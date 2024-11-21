package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIOClient
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import io.patterueldev.client.ClientType
import io.patterueldev.jwt.JwtUtil
import io.patterueldev.reservation.next.SkipSongParameters
import io.patterueldev.room.Room
import io.patterueldev.singalong.ServerCoordinator
import io.patterueldev.singalong.SingalongService
import kotlinx.coroutines.runBlocking
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Profile
import org.springframework.stereotype.Component

typealias OnEventListener = () -> Unit

@Component
@Profile("!test")
class SingalongSocketIOModule(
    @Autowired private val server: SocketIOServer,
    @Autowired private val jwtUtil: JwtUtil,
    @Autowired private val singalongService: SingalongService,
    @Autowired private val serverCoordinator: ServerCoordinator,
) {
    private var idleNamespace: SocketIONamespace = server.addNamespace("/idle")
    private val roomNamespaces = mutableListOf<SocketIONamespace>()

    private var volume: Double = 1.0

    init {
        setupIdleNamespace()
        updateRoomNamespaces()

        serverCoordinator.onReserveUpdateListener = { broadcastReservedSongsToRoom(it) }
        serverCoordinator.onCurrentSongUpdateListener = { broadcastCurrentSongData(it) }
        serverCoordinator.onAssignedPlayerToRoomListener = { playerId, roomId -> assignPlayerToRoom(playerId, roomId) }
        serverCoordinator.onRoomUpdateListener = ::updateRoomNamespaces
    }

    private fun setupIdleNamespace() {
        // Idle Connect listener
        idleNamespace.addConnectListener({ client ->
            // get extra headers
            val handshakeData: HandshakeData = client.handshakeData
            val headers = handshakeData.httpHeaders

            println("Idle namespace connected: $headers")
            val playerId = headers["playerName"]
            val deviceId = headers["deviceId"]
            println("Registering $playerId from $deviceId")
            // TODO: Handle if not player. This space is mostly for the player.
            val existing = idleNamespace.allClients.find { it.get<String>("name") == playerId }
            if (existing != null) {
                // check if it's the same device
                if (existing.get<String>("deviceId") == deviceId) {
                    println("Already connected with same device ID. Will disconnect existing...")
                    existing.disconnect()
                } else {
                    client.disconnect()
                    println("$playerId is already connected from another device.")
                    return@addConnectListener
                }
            }
            client.set("name", playerId)
            client.set("deviceId", deviceId)

            // send players list to admin
            roomNamespaces.forEach { roomNamespace ->
                broadcastPlayerListToAdmin(roomNamespace, listOf(client))
            }
        })

        // Idle Disconnect listener
        idleNamespace.addDisconnectListener { client ->
            println("Idle namespace disconnected: ${client.get<String>("name")}")

            // send players list to admin
            roomNamespaces.forEach { roomNamespace ->
                broadcastPlayerListToAdmin(roomNamespace)
            }
        }

        val event = SocketEvent.IDLE_RECONNECT_ATTEMPT.value
        println("Listening to event: $event")
        idleNamespace.addEventListener(event, String::class.java) { client, playerId, _ ->
            println("Reconnect attempt event received: $playerId")

            // run a check if the player is already assigned to a room
            runBlocking {
                println("Checking if player $playerId is already assigned to a room...")
                val assignedRoom = singalongService.getAssignedRoom(playerId)
                println("Assigned room: $assignedRoom")
                if (assignedRoom != null) {
                    println("Player $playerId is already assigned to room $assignedRoom")
                    assignPlayerToRoom(playerId, assignedRoom.id, client)
                }
            }
        }
    }

    private fun updateRoomNamespaces() {
        val rooms = singalongService.getActiveRooms()
        val roomIds = rooms.map { it.id }
        val roomNamespaceNames = roomIds.map { "/room/$it" }
        val namespaceIndecesToBeRemoved = mutableListOf<Int>()
        roomNamespaces.forEach { namespace ->
            val roomStillExists = roomNamespaceNames.contains(namespace.name)
            if (!roomStillExists) {
                println("Room with namespace ${namespace.name} was removed. Shutting down...")
                namespace.allClients.forEach { client ->
                    client.disconnect()
                }
                // Remove the namespace from the server
                server.removeNamespace(namespace.name)
                println("Namespace ${namespace.name} has been shut down.")
                val index = roomNamespaces.indexOf(namespace)
                namespaceIndecesToBeRemoved.add(index)
            } else {
                println("Namespace ${namespace.name} still intact.")
            }
        }

        namespaceIndecesToBeRemoved.sortedDescending().forEach {
            roomNamespaces.removeAt(it)
        }

        // create new namespace
        rooms.forEach { room ->
            val namespaceName = "/room/${room.id}"
            val existing = server.allNamespaces.firstOrNull { it.name == namespaceName }
            if (existing == null) {
                createNamespaceForRoom(room)
            }
        }
    }

    private fun createNamespaceForRoom(room: Room) {
        val namespaceName = "/room/${room.id}"
        val namespace = server.addNamespace(namespaceName)
        roomNamespaces.add(namespace)
        println("Created namespace for $room named $namespaceName")

        // setup listeners, etc.
        // Room Connect listener
        namespace.addConnectListener { client ->
            val handshakeData: HandshakeData = client.handshakeData
            var token: String? = null
            val authorizationHeader = handshakeData.httpHeaders["Authorization"]
            if (authorizationHeader != null) {
                token = authorizationHeader.replace("Bearer ", "")
            } else {
                // try auth
                val query = handshakeData.authToken
                println("Client[${client.sessionId}] - Query: $query")
                if (query is Map<*, *>) {
                    token = query["token"] as String?
                }
            }

            if (token == null) {
                client.sendEvent("error", "Missing token.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to missing token.")
                return@addConnectListener
            }

            if (!jwtUtil.isTokenValid(token)) {
                client.sendEvent("error", "Invalid token.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to invalid token.")
                return@addConnectListener
            }

            val userDetails = jwtUtil.getUserDetails(token)
            val username = userDetails.username
            val accessRoomID = userDetails.roomId
            val deviceId = userDetails.deviceId
            val clientType = userDetails.clientType

            // check if the roomId is the same as the namespace's room id
            if (accessRoomID != room.id) {
                client.sendEvent("error", "Room ID does not match.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to mismatched room ID $accessRoomID at $namespaceName")
                return@addConnectListener
            }

            println("Client[${client.sessionId}] - Connected to room $accessRoomID module as '$username' in room '$accessRoomID'")

            client.set("username", username)
            client.set("roomId", accessRoomID)
            client.set("deviceId", deviceId)
            client.set("clientType", clientType.name)

            when (clientType) {
                ClientType.PLAYER -> {
                    // broadcast to admin
                    broadcastPlayerListToAdmin(namespace)
                }
                ClientType.CONTROLLER -> {
                    // broadcast to admin and player
                    broadcastParticipantsToRoom(room.id, namespace)
                }
                ClientType.ADMIN -> {
                    // broadcast to admin and player
                    broadcastParticipantsToRoom(room.id, namespace)
                }
            }
        }

        // Room Disconnect listener
        namespace.addDisconnectListener { client ->
            println("Client[${client.sessionId}] - Disconnected from room ${room.id} module.")
        }

        // Room Namespace Events
        val roomDataRequestEvent = SocketEvent.ROOM_DATA_REQUEST.value
        println("Listening to event: $roomDataRequestEvent for room ${room.id}")
        namespace.addEventListener(roomDataRequestEvent, String::class.java) { client, dataTypesRaw, _ ->
            println("Client[${client.sessionId}] - Admin room data request event received: $dataTypesRaw")
            // requestType could be: reservedSongs, currentSong, playerList
            // if all, send all data

            val dataTypes =
                dataTypesRaw.split(",").map {
                    RoomDataType.fromString(it)
                }

            val allOrType: (RoomDataType) -> Boolean = { dataTypes.contains(RoomDataType.ALL) || dataTypes.contains(it) }

            var broadcasts = 0
            if (allOrType(RoomDataType.RESERVED_SONGS)) {
                broadcastReservedSongsToRoom(room.id, namespace, listOf(client))
                broadcasts++
            }

            if (allOrType(RoomDataType.CURRENT_SONG)) {
                broadcastCurrentSongData(room.id, namespace, listOf(client))
                broadcasts++
            }

            if (allOrType(RoomDataType.PLAYER_LIST)) {
                broadcastPlayerListToAdmin(namespace, listOf(client))
                broadcasts++
            }

            if (allOrType(RoomDataType.ASSIGNED_PLAYER_IN_ROOM)) {
                broadcastAssignedPlayerToRoom(namespace, listOf(client))
                broadcasts++
            }

            if (allOrType(RoomDataType.PARTICIPANTS_LIST)) {
                broadcastParticipantsToRoom(room.id, namespace, listOf(client))
                broadcasts++
            }

            if (broadcasts == 0) {
                println("Client[${client.sessionId}] - Data types received are not supported: $dataTypes.")
            }
        }

        val roomPlayerCommandEvent = SocketEvent.ROOM_PLAYER_COMMAND.value
        println("Listening to event: $roomPlayerCommandEvent for room ${room.id}")
        namespace.addEventListener(roomPlayerCommandEvent, String::class.java) { client, commandRaw, _ ->

            val mapper = jacksonObjectMapper()
            val command = mapper.readValue(commandRaw, Map::class.java)
            val type = command["type"] as String
            val data = command["data"]
            val commandType = RoomCommandType.fromString(type)

            if (commandType != RoomCommandType.DURATION_UPDATE) {
                println("Client[${client.sessionId}] - Room player command event received: $commandRaw")
            }

            when (commandType) {
                RoomCommandType.SKIP_SONG -> {
                    println("Client[${client.sessionId}] - Skip song event received.")
                    var completed = false
                    if (data is Boolean) {
                        completed = data
                    }
                    val roomId: String = client.get("roomId")
                    val parameters = SkipSongParameters(roomId, completed)
                    singalongService.skipSong(parameters)
                }
                RoomCommandType.TOGGLE_PLAY_PAUSE -> {
                    println("Client[${client.sessionId}] - Toggle play/pause event received.")
                    // broadcasted to all; even controllers can toggle
                    if (data is Boolean) broadcastEventInRoom(SocketEvent.TOGGLE_PLAY_PAUSE, data, roomId = room.id, namespace = namespace)
                }
                RoomCommandType.ADJUST_VOLUME -> {
                    println("Client[${client.sessionId}] - Adjust volume event received.")
                    if (data is Double) {
                        this.volume = data
                        broadcastEventInRoom(
                            SocketEvent.ADJUST_VOLUME_FROM_CONTROL,
                            data,
                            ClientType.PLAYER,
                            roomId = room.id,
                            namespace = namespace,
                        )
                    }
                }
                RoomCommandType.SEEK_DURATION -> {
                    println("Client[${client.sessionId}] - Seek duration event received.")
                    // will only send to player, which should only be one
                    if (data is Int) {
                        broadcastEventInRoom(
                            SocketEvent.SEEK_DURATION,
                            data,
                            ClientType.PLAYER,
                            roomId = room.id,
                            namespace = namespace,
                        )
                    }
                }
                RoomCommandType.DURATION_UPDATE -> {
//                    println("Client[${client.sessionId}] - Duration update event received.")
                    // will only send to admins
                    if (data is Int) {
                        broadcastEventInRoom(
                            SocketEvent.DURATION_UPDATE,
                            data,
                            ClientType.ADMIN,
                            roomId = room.id,
                            namespace = namespace,
                        )
                    }
                }
            }
        }
    }

    private fun broadcastEventInRoom(
        event: SocketEvent,
        data: Any,
        clientType: ClientType? = null,
        roomId: String,
        namespace: SocketIONamespace? = null,
    ) {
        val roomNamespace = namespace ?: roomNamespaces.find { it.name == "/room/$roomId" } ?: return
        val clients =
            roomNamespace.allClients.filter {
                if (clientType == null) return@filter true
                it.get<String>("clientType") == clientType.name
            }
        clients.forEach { it.sendEvent(event.value, data) }
    }

    private fun broadcastReservedSongsToRoom(
        roomId: String,
        namespace: SocketIONamespace? = null,
        clients: List<SocketIOClient>? = null,
    ) {
        println("Reservation success event received.")
        // Handle the event, e.g., update the reserved songs list
        val reservedSongs = singalongService.getReservedSongs(roomId)
        val roomNamespace = namespace ?: roomNamespaces.find { it.name == "/room/$roomId" } ?: return
        if (clients != null) {
            clients.forEach { it.sendEvent(SocketEvent.RESERVED_SONGS.value, reservedSongs) }
        } else {
            roomNamespace.broadcastOperations.sendEvent(SocketEvent.RESERVED_SONGS.value, reservedSongs)
        }

        // also broadcast participants since reserved songs are updated
        broadcastParticipantsToRoom(roomId, namespace, clients)
    }

    private fun broadcastCurrentSongData(
        roomId: String,
        namespace: SocketIONamespace? = null,
        clients: List<SocketIOClient>? = null,
    ) {
        println("Current song update event received.")
        // Handle the event, e.g., update the current song
        val currentSong = singalongService.getCurrentSong(roomId)
        val roomNamespace = namespace ?: roomNamespaces.find { it.name == "/room/$roomId" } ?: return
        println("Is null? ${currentSong == null}")
        if (clients != null) {
            clients.forEach {
                currentSong?.volume = volume
                it.sendEvent(SocketEvent.CURRENT_SONG.value, currentSong)
            }
        } else {
            roomNamespace.broadcastOperations.sendEvent(SocketEvent.CURRENT_SONG.value, currentSong)
        }
    }

    private fun broadcastPlayerListToAdmin(
        namespace: SocketIONamespace,
        clients: List<SocketIOClient>? = null,
    ) {
        println("Sending players list to admin.")
        // Get clients with type PLAYER
        val playerClients = idleNamespace.allClients
        val players =
            playerClients.map {
                // get player name from socket
                val deviceId = it.get<String>("deviceId")
                val playerName = it.get<String>("name")
                object : PlayerItem {
                    override val id: String = deviceId
                    override val name: String = playerName
                    override val isIdle: Boolean = playerInRoom(namespace) == null
                }
            }
        // send to admin
        val adminClients = clients ?: namespace.allClients.filter { it.get<String>("clientType") == ClientType.ADMIN.name }
        adminClients.forEach { it.sendEvent(SocketEvent.PLAYERS_LIST.value, players) }
        println("Sent players list to admin: ${players.size}")
    }

    private fun broadcastAssignedPlayerToRoom(
        namespace: SocketIONamespace,
        clients: List<SocketIOClient>? = null,
    ) {
        val playerInRoom =
            playerInRoom(namespace)?.let {
                object : PlayerItem {
                    override val id: String = it.get("deviceId")
                    override val name: String = it.get("username")
                    override val isIdle: Boolean = false
                }
            }
        val adminClients = clients ?: namespace.allClients.filter { it.get<String>("clientType") == ClientType.ADMIN.name }
        adminClients.forEach { it.sendEvent(SocketEvent.PLAYER_ASSIGNED.value, playerInRoom) }
    }

    private fun assignPlayerToRoom(
        playerId: String,
        roomId: String,
        client: SocketIOClient? = null,
    ) {
        println("Player assigned to room: $playerId, $roomId")
        val playerClient = client ?: idleNamespace.allClients.find { it.get<String>("name") == playerId } ?: return
        println("Player client found: $playerClient")
        playerClient.sendEvent(SocketEvent.ROOM_ASSIGNED.value, roomId)
    }

    private fun playerInRoom(namespace: SocketIONamespace): SocketIOClient? {
        return namespace.allClients.find { it.get<String>("clientType") == ClientType.PLAYER.name }
    }

    private fun broadcastParticipantsToRoom(
        roomId: String,
        namespace: SocketIONamespace? = null,
        clients: List<SocketIOClient>? = null,
    ) {
        val participantsInRoom = singalongService.getParticipantsInRoom(roomId)
        val roomNamespace = namespace ?: roomNamespaces.find { it.name == "/room/$roomId" } ?: return
        val roomClients = clients ?: roomNamespace.allClients.filter { it.get<String>("clientType") != ClientType.CONTROLLER.name }
        println("Sending ${participantsInRoom.size} participants to ${roomClients.size} room clients")
        roomClients.forEach { it.sendEvent(SocketEvent.PARTICIPANTS_LIST.value, participantsInRoom) }
    }
}

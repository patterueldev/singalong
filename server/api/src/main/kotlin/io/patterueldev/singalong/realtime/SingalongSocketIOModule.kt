package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIOClient
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import io.patterueldev.client.ClientType
import io.patterueldev.jwt.JwtUtil
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

    init {
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

            // run a check if the player is already assigned to a room
            runBlocking {
                println("Checking if player $playerId is already assigned to a room...")
                val assignedRoom = singalongService.getAssignedRoom(playerId)
                println("Assigned room: $assignedRoom")
                if (assignedRoom != null) {
                    println("Player $playerId is already assigned to room $assignedRoom")
                    broadcastAssignedPlayerToRoom(playerId, assignedRoom.id, client)
                }
            }
        })

        idleNamespace.addDisconnectListener { client ->
            println("Idle namespace disconnected: ${client.get<String>("name")}")

            // send players list to admin
            roomNamespaces.forEach { roomNamespace ->
                broadcastPlayerListToAdmin(roomNamespace)
            }
        }

        updateRoomNamespaces()

        serverCoordinator.onReserveUpdateListener = { broadcastReservedSongs(it) }
        serverCoordinator.onCurrentSongUpdateListener = { broadcastCurrentSongData(it) }
        serverCoordinator.onAssignedPlayerToRoomListener = { playerId, roomId -> broadcastAssignedPlayerToRoom(playerId, roomId) }
        serverCoordinator.onRoomUpdateListener = ::updateRoomNamespaces
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
            client.set("clientType", clientType.name)
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
                broadcastReservedSongs(room.id, namespace)
                broadcasts++
            }

            if (allOrType(RoomDataType.CURRENT_SONG)) {
                broadcastCurrentSongData(room.id, namespace)
                broadcasts++
            }

            if (allOrType(RoomDataType.PLAYER_LIST)) {
                broadcastPlayerListToAdmin(namespace, listOf(client))
                broadcasts++
            }

            if (broadcasts == 0) {
                println("Client[${client.sessionId}] - Data types received are not supported: $dataTypes.")
            }
        }

        val roomPlayerCommandEvent = SocketEvent.ROOM_PLAYER_COMMAND.value
        println("Listening to event: $roomPlayerCommandEvent for room ${room.id}")
        namespace.addEventListener(roomPlayerCommandEvent, String::class.java) { client, commandRaw, _ ->

            println("Client[${client.sessionId}] - Room player command event received: $commandRaw")

            val mapper = jacksonObjectMapper()
            val command = mapper.readValue(commandRaw, Map::class.java)
            val type = command["type"] as String
            val data = command["data"]
            val commandType = RoomCommandType.fromString(type)

            when (commandType) {
                RoomCommandType.SKIP_SONG -> {
                    println("Client[${client.sessionId}] - Skip song event received.")
                    singalongService.skipSong(roomId = client.get("roomId"))
                }
                RoomCommandType.TOGGLE_PLAY_PAUSE -> {
                    println("Client[${client.sessionId}] - Toggle play/pause event received.")
                    // broadcasted to all; even controllers can toggle
                    if (data is Boolean) broadcastEventInRoom(SocketEvent.TOGGLE_PLAY_PAUSE, data)
                }
                RoomCommandType.ADJUST_VOLUME -> {
                    println("Client[${client.sessionId}] - Adjust volume event received.")
                    if (data is Double) {
                        broadcastEventInRoom(SocketEvent.ADJUST_VOLUME_FROM_CONTROL, data, ClientType.PLAYER)
                    }
                }
                RoomCommandType.SEEK_DURATION -> {
                    println("Client[${client.sessionId}] - Seek duration event received.")
                    // will only send to player, which should only be one
                    if (data is Int) broadcastEventInRoom(SocketEvent.SEEK_DURATION, data, ClientType.PLAYER)
                }
                RoomCommandType.DURATION_UPDATE -> {
                    println("Client[${client.sessionId}] - Duration update event received.")
                    // will only send to admins
                    if (data is Int) broadcastEventInRoom(SocketEvent.DURATION_UPDATE, data, ClientType.ADMIN)
                }
            }
        }
    }

    private fun broadcastEventInRoom(
        event: SocketEvent,
        data: Any,
        clientType: ClientType? = null,
    ) {
        roomNamespaces.forEach { roomNamespace ->
            val adminClients =
                roomNamespace.allClients.filter {
                    if (clientType == null) return@filter true
                    it.get<String>("clientType") == clientType.name
                }
            adminClients.forEach { it.sendEvent(event.value, data) }
        }
    }

    private fun broadcastReservedSongs(
        roomId: String,
        namespace: SocketIONamespace? = null,
    ) {
        println("Reservation success event received.")
        // Handle the event, e.g., update the reserved songs list
        val reservedSongs = singalongService.getReservedSongs(roomId)
        val ns = namespace ?: roomNamespaces.find { it.name == "/room/$roomId" }
        // Broadcast the event to all active clients
        ns?.broadcastOperations?.sendEvent(SocketEvent.RESERVED_SONGS.value, reservedSongs)
    }

    private fun broadcastCurrentSongData(
        roomId: String,
        namespace: SocketIONamespace? = null,
    ) {
        println("Current song update event received.")
        // Handle the event, e.g., update the current song
        val currentSong = singalongService.getCurrentSong(roomId)
        val ns = namespace ?: roomNamespaces.find { it.name == "/room/$roomId" }
        println("Is null? ${currentSong == null}")
        // Broadcast the event to all active clients
        ns?.broadcastOperations?.sendEvent(SocketEvent.CURRENT_SONG.value, currentSong)
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
                }
            }
        // send to admin
        val adminClients = clients ?: namespace.allClients.filter { it.get<String>("clientType") == ClientType.ADMIN.name }
        adminClients.forEach { it.sendEvent(SocketEvent.PLAYERS_LIST.value, players) }
        println("Sent players list to admin: ${players.size}")
    }

    private fun broadcastAssignedPlayerToRoom(
        playerId: String,
        roomId: String,
        client: SocketIOClient? = null,
    ) {
        println("Player assigned to room: $playerId, $roomId")
        val playerClient = client ?: idleNamespace.allClients.find { it.get<String>("name") == playerId } ?: return
        println("Player client found: $playerClient")
        playerClient.sendEvent(SocketEvent.ROOM_ASSIGNED.value, roomId)
    }
}

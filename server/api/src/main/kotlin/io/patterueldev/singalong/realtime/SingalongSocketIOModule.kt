package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIOClient
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.corundumstudio.socketio.listener.ConnectListener
import com.corundumstudio.socketio.listener.DisconnectListener
import io.patterueldev.client.ClientType
import io.patterueldev.jwt.JwtUtil
import io.patterueldev.singalong.ServerCoordinator
import io.patterueldev.singalong.SingalongService
import kotlinx.coroutines.runBlocking
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component

typealias OnEventListener = () -> Unit

@Component
class SingalongSocketIOModule(
    @Autowired private val server: SocketIOServer,
    @Autowired private val jwtUtil: JwtUtil,
    @Autowired private val singalongService: SingalongService,
    @Autowired private val serverCoordinator: ServerCoordinator,
) {
    private var namespace: SocketIONamespace = server.addNamespace("/singalong")

    init {
        namespace.addConnectListener(onConnected())
        namespace.addDisconnectListener(onDisconnected())
        serverCoordinator.setOnReserveUpdateListener(::onReserveSuccess)
        serverCoordinator.setOnCurrentSongUpdateListener(::onCurrentSongUpdate)
        serverCoordinator.setOnAssignedPlayerToRoomListener(::onAssignedPlayerToRoom)

        val requestPlayersListEvent = SocketEvent.REQUEST_PLAYERS_LIST.value
        println("Listening to event: $requestPlayersListEvent")
        namespace.addEventListener(requestPlayersListEvent, String::class.java) { client, data, _ ->
            println("Client[${client.sessionId}] - Request players list event received: $data")
            sendPlayersList(listOf(client))
        }

        val seekDurationFromPlayerEvent = SocketEvent.SEEK_DURATION_FROM_PLAYER.value
        namespace.addEventListener(seekDurationFromPlayerEvent, String::class.java) { client, data, _ ->
            val username = client.get<String>("username")
            val roomId = client.get<String>("roomId")
            val seekDuration = data.toInt()
            val adminClients = server.getNamespace("/singalong").allClients.filter { it.get<String>("clientType") == ClientType.ADMIN.name }
            adminClients.forEach { it.sendEvent(seekDurationFromPlayerEvent, seekDuration) }
        }

        val seekDurationFromControlEvent = SocketEvent.SEEK_DURATION_FROM_CONTROL.value
        namespace.addEventListener(seekDurationFromControlEvent, String::class.java) { client, data, _ ->
            val username = client.get<String>("username")
            val roomId = client.get<String>("roomId")
            val seek = data.toInt()
            println("Client[$username] - Seek: $seek")
            val playerClients =
                server.getNamespace(
                    "/singalong",
                ).allClients.filter { it.get<String>("clientType") == ClientType.PLAYER.name }
            playerClients.forEach { it.sendEvent(seekDurationFromControlEvent, seek) }
        }

        val skipSongEvent = SocketEvent.SKIP_SONG.value
        namespace.addEventListener(skipSongEvent, String::class.java) { client, _, _ ->
            println("Client[${client.sessionId}] - Skip song event received.")
            runBlocking {
                val result =
                    singalongService.skipSong(
                        username = client.get("username"),
                        roomId = client.get("roomId"),
                    )
                println("Skip song result: $result")
            }
        }

        val togglePlayPauseEvent = SocketEvent.TOGGLE_PLAY_PAUSE.value
        namespace.addEventListener(togglePlayPauseEvent, Boolean::class.java) { client, data, _ ->
            println("Client[${client.sessionId}] - Toggle play/pause event received: $data")
            namespace.broadcastOperations.sendEvent(togglePlayPauseEvent, data)
        }

        val adjustVolumeFromControlEvent = SocketEvent.ADJUST_VOLUME_FROM_CONTROL.value
        namespace.addEventListener(adjustVolumeFromControlEvent, Double::class.java) { client, data, _ ->
            println("Client[${client.sessionId}] - Adjust volume event received: $data")
            namespace.broadcastOperations.sendEvent(adjustVolumeFromControlEvent, data)
        }
    }

    private fun onReserveSuccess() {
        println("Reservation success event received.")
        // Handle the event, e.g., update the reserved songs list
        val reservedSongs = singalongService.getReservedSongs()
        // Broadcast the event to all active clients
        namespace.broadcastOperations.sendEvent(SocketEvent.RESERVED_SONGS.value, reservedSongs)
    }

    private fun onCurrentSongUpdate() {
        println("Current song update event received.")
        // Handle the event, e.g., update the current song
        val currentSong = singalongService.getCurrentSong()
        // Broadcast the event to all active clients
        namespace.broadcastOperations.sendEvent(SocketEvent.CURRENT_SONG.value, currentSong)
    }

    private fun onConnected(): ConnectListener {
        return ConnectListener { client ->
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
                return@ConnectListener
            }

            if (!jwtUtil.isTokenValid(token)) {
                client.sendEvent("error", "Invalid token.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to invalid token.")
                return@ConnectListener
            }

            val userDetails = jwtUtil.getUserDetails(token)
            val username = userDetails.username
            val roomId = userDetails.roomId
            val clientType = userDetails.clientType

            // check if room is the active room
            if (clientType == ClientType.CONTROLLER) {
                if (roomId != singalongService.activeRoom?.id) {
                    client.sendEvent("error", "Room is not active.")
                    client.disconnect()
                    println("Client[${client.sessionId}] - Connection rejected due to inactive room.")
                    return@ConnectListener
                }
            }

            println("Client[${client.sessionId}] - Connected to chat module as '$username' in room '$roomId'")
            client.sendEvent("connected", "You are now connected to the chat module.")

            client.set("username", username)
            client.set("roomId", roomId)
            client.set("clientType", clientType.name)

            when (clientType) {
                ClientType.CONTROLLER -> {
                    val reservedSongs = singalongService.getReservedSongs()
                    client.sendEvent(SocketEvent.RESERVED_SONGS.value, reservedSongs)
                }
                ClientType.ADMIN -> {
                    val currentSong = singalongService.getCurrentSong()
                    println("Is null? ${currentSong == null}")
                    client.sendEvent(SocketEvent.CURRENT_SONG.value, currentSong)
                }
                ClientType.PLAYER -> {
                    val currentSong = singalongService.getCurrentSong()
                    println("Is null? ${currentSong == null}")
                    client.sendEvent(SocketEvent.CURRENT_SONG.value, currentSong)

                    val reservedSongs = singalongService.getReservedSongs()
                    client.sendEvent(SocketEvent.RESERVED_SONGS.value, reservedSongs)

                    sendPlayersList()
                }
            }
        }
    }

    private fun onDisconnected(): DisconnectListener {
        return DisconnectListener { client ->
            println("Client[${client.sessionId}] - Disconnected from chat module.")
        }
    }

    private fun sendPlayersList(clients: List<SocketIOClient> = listOf()) {
        println("Sending players list to admin.")
        // Get clients with type PLAYER
        val playerClients = namespace.allClients.filter { it.get<String>("clientType") == ClientType.PLAYER.name }
        val players =
            playerClients.map {
                // get player ID from socket
                val playerId = it.sessionId
                // get player name from socket
                val playerName = it.get<String>("username")
                object : PlayerItem {
                    override val id: String = playerId.toString()
                    override val name: String = playerName
                }
            }
        // send to admin
        if (clients.isEmpty()) {
            val adminClients = namespace.allClients.filter { it.get<String>("clientType") == ClientType.ADMIN.name }
            adminClients.forEach { it.sendEvent(SocketEvent.PLAYERS_LIST.value, players) }
        } else {
            clients.forEach { it.sendEvent(SocketEvent.PLAYERS_LIST.value, players) }
        }
        println("Sent players list to admin: ${players.size}")
    }

    private fun onAssignedPlayerToRoom(
        playerId: String,
        roomId: String,
    ) {
        println("Player assigned to room: $playerId, $roomId")
        val playerClient = namespace.allClients.find { it.get<String>("username") == playerId }
        playerClient?.sendEvent(SocketEvent.ROOM_ASSIGNED.value, roomId)
    }
}

interface PlayerItem {
    val id: String
    val name: String
}

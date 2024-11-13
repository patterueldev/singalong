package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
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

        val seekDurationEvent = SocketEvent.SEEK_DURATION_FROM_PLAYER.value
        namespace.addEventListener(seekDurationEvent, String::class.java) { client, data, _ ->
            val username = client.get<String>("username")
            val roomId = client.get<String>("roomId")
            val seekDuration = data.toInt()
            namespace.broadcastOperations.sendEvent(seekDurationEvent, seekDuration)
        }

        val seekEvent = SocketEvent.SEEK_DURATION_FROM_CONTROL.value
        namespace.addEventListener(seekEvent, String::class.java) { client, data, _ ->
            val username = client.get<String>("username")
            val roomId = client.get<String>("roomId")
            val seek = data.toInt()
            println("Client[$username] - Seek: $seek")
            namespace.broadcastOperations.sendEvent(seekEvent, seek)
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
            if (roomId != singalongService.activeRoom.id) {
                client.sendEvent("error", "Room is not active.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to inactive room.")
                return@ConnectListener
            }

            println("Client[${client.sessionId}] - Connected to chat module as '$username' in room '$roomId'")
            client.sendEvent("connected", "You are now connected to the chat module.")

            client.set("username", username)
            client.set("roomId", roomId)

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
                }
            }
        }
    }

    private fun onDisconnected(): DisconnectListener {
        return DisconnectListener { client ->
            println("Client[${client.sessionId}] - Disconnected from chat module.")
        }
    }
}

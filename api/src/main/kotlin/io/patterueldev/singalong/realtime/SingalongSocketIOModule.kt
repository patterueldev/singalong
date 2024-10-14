package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.corundumstudio.socketio.listener.ConnectListener
import com.corundumstudio.socketio.listener.DisconnectListener
import io.patterueldev.client.ClientType
import io.patterueldev.session.jwt.JwtUtil
import io.patterueldev.singalong.ServerCoordinator
import io.patterueldev.singalong.SingalongService
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component

typealias OnReserveSuccessListener = () -> Unit

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
        serverCoordinator.setOnReserveSuccessListener(::onReserveSuccess)
    }

    private fun onReserveSuccess() {
        println("Reservation success event received.")
        // Handle the event, e.g., update the reserved songs list
        val reservedSongs = singalongService.getReservedSongs()
        // Broadcast the event to all active clients
        namespace.broadcastOperations.sendEvent("reservedSongs", reservedSongs)
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
                    client.sendEvent("reservedSongs", reservedSongs)
                }
                ClientType.ADMIN -> TODO()
                ClientType.PLAYER -> TODO()
            }
        }
    }

    private fun onDisconnected(): DisconnectListener {
        return DisconnectListener { client ->
            println("Client[${client.sessionId}] - Disconnected from chat module.")
        }
    }
}

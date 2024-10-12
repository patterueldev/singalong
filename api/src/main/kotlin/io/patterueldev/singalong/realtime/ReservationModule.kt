package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.corundumstudio.socketio.listener.ConnectListener
import com.corundumstudio.socketio.listener.DataListener
import com.corundumstudio.socketio.listener.DisconnectListener
import io.patterueldev.reservation.ReservationService
import io.patterueldev.session.jwt.JwtAuthenticationProvider
import io.patterueldev.session.jwt.JwtUtil
import kotlinx.coroutines.runBlocking
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component

@Component
class ReservationModule(
    @Autowired private val server: SocketIOServer,
    @Autowired private val jwtUtil: JwtUtil,
    @Autowired private val reservationService: ReservationService,
) {
    private var namespace: SocketIONamespace = server.addNamespace("/reservations")

    init {
        namespace.addConnectListener(onConnected())
        namespace.addDisconnectListener(onDisconnected())
        namespace.addEventListener("chat", String::class.java, onChatReceived())
    }

    private fun onChatReceived(): DataListener<String> {
        return DataListener { client, data, ackSender ->
            val username: String? = client.get("username")
            val roomId: String? = client.get("roomId")

            if (username == null || roomId == null) {
                client.sendEvent("error", "Missing username or roomId.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to missing username or roomId.")
                return@DataListener
            }

            println("Client[${client.sessionId}] - Received chat message from '$username' in room '$roomId': $data")

            namespace.broadcastOperations.sendEvent("chat", data)
        }
    }

    private fun onConnected(): ConnectListener {
        return ConnectListener { client ->
            val handshakeData: HandshakeData = client.handshakeData
            val token = handshakeData.httpHeaders["Authorization"]?.replace("Bearer ", "")
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

            val username = jwtUtil.extractSubject(token)
            val roomId = jwtUtil.extractRoomId(token)

            println("Client[${client.sessionId}] - Connected to chat module as '$username' in room '$roomId'")
            client.sendEvent("connected", "You are now connected to the chat module.")

            client.set("username", username)
            client.set("roomId", roomId)

            // TODO: Send list of reserved songs to the client
//            val reservedSongs = runBlocking {
//                reservationService.loadReservationList()
//            }
//            client.sendEvent("reservedSongs", reservedSongs)
        }
    }

    private fun onDisconnected(): DisconnectListener {
        return DisconnectListener { client ->
            println("Client[${client.sessionId}] - Disconnected from chat module.")
        }
    }
}

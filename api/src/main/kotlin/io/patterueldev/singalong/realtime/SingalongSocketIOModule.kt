package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.corundumstudio.socketio.listener.ConnectListener
import com.corundumstudio.socketio.listener.DataListener
import com.corundumstudio.socketio.listener.DisconnectListener
import io.patterueldev.client.ClientType
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.reservation.reservedsong.ReservedSong
import io.patterueldev.session.jwt.JwtUtil
import kotlinx.coroutines.runBlocking
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component

@Component
class SingalongSocketIOModule(
    @Autowired private val server: SocketIOServer,
    @Autowired private val jwtUtil: JwtUtil,
    @Autowired private val reservationService: ReservationService,
) {
    private var namespace: SocketIONamespace = server.addNamespace("/singalong")

    private val reservedSongs = mutableListOf<ReservedSong>()

    init {
        namespace.addConnectListener(onConnected())
        namespace.addDisconnectListener(onDisconnected())
        namespace.addEventListener("command", String::class.java, onCommandReceived())

        // TODO: find a way to obtain the room ID at this point
        // because there's supposed to be only one room in a session, and one socket server per session
//        val reservedSongs = runBlocking {
//            reservationService.loadReservationList(
//                parameters = LoadReservationListParameters("admin") // TODO: Temporary
//            )
//        }.data!!
//        this.reservedSongs.addAll(reservedSongs)
//
//        namespace.addEventListener("reservations", String::class.java) { client, data, ackSender ->
//            ackSender.sendAckData(reservedSongs)
//        }
    }

    private fun onCommandReceived(): DataListener<String> {
        return DataListener { client, data, ackSender ->
            val username: String? = client.get("username")
            val roomId: String? = client.get("roomId")

            if (username == null || roomId == null) {
                client.sendEvent("error", "Missing username or roomId.")
                client.disconnect()
                println("Client[${client.sessionId}] - Connection rejected due to missing username or roomId.")
                return@DataListener
            }

            println("Client[${client.sessionId}] - Received command from '$username' in room '$roomId': $data")
            when (data) {
                "reservations" -> {
                }
            }
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

            val userDetails = jwtUtil.getUserDetails(token)
            val username = userDetails.username
            val roomId = userDetails.roomId
            val clientType = userDetails.clientType

            println("Client[${client.sessionId}] - Connected to chat module as '$username' in room '$roomId'")
            client.sendEvent("connected", "You are now connected to the chat module.")

            client.set("username", username)
            client.set("roomId", roomId)

            when (clientType) {
                ClientType.CONTROLLER -> {
                    val reservedSongs = runBlocking {
                        reservationService.loadReservationList(
                            parameters = LoadReservationListParameters(roomId)
                        )
                    }
                    client.sendEvent("reservedSongs", reservedSongs)

                    // TODO: listen to database changes instead of polling

                }

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

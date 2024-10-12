package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIONamespace
import com.corundumstudio.socketio.SocketIOServer
import com.corundumstudio.socketio.listener.ConnectListener
import com.corundumstudio.socketio.listener.DataListener
import com.corundumstudio.socketio.listener.DisconnectListener
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component

@Component
class ReservationModule(
    @Autowired private val server: SocketIOServer,
) {
    private var namespace: SocketIONamespace = server.addNamespace("/reservations")

    init {
        namespace.addConnectListener(onConnected())
        namespace.addDisconnectListener(onDisconnected())
        namespace.addEventListener("chat", String::class.java, onChatReceived())
    }

    private fun onChatReceived(): DataListener<String> {
        return DataListener { client, data, ackSender ->
            println("Client[${client.sessionId}] - Received chat message '$data'")
            namespace.broadcastOperations.sendEvent("chat", data)
        }
    }

    private fun onConnected(): ConnectListener {
        return ConnectListener { client ->
            val handshakeData: HandshakeData = client.handshakeData
            println("Client[${client.sessionId}] - Connected to chat module through '${handshakeData.url}'")

            // TODO: Send list of reserved songs to the client
        }
    }

    private fun onDisconnected(): DisconnectListener {
        return DisconnectListener { client ->
            println("Client[${client.sessionId}] - Disconnected from chat module.")
        }
    }
}

package io.patterueldev.singalong.realtime

import com.corundumstudio.socketio.SocketIOServer
import jakarta.annotation.PreDestroy
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component

@Component
class ServerCommandLineRunner : CommandLineRunner {
    @Autowired
    private lateinit var server: SocketIOServer

    @Throws(Exception::class)
    override fun run(vararg args: String) {
        server.start()
    }

    @PreDestroy
    fun stopServer() {
        server.stop()
    }
}

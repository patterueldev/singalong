package io.patterueldev.singalong

import com.corundumstudio.socketio.Configuration
import com.corundumstudio.socketio.SocketIOServer
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.ComponentScan
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories

@SpringBootApplication
@ComponentScan("io.patterueldev")
@EnableMongoRepositories(basePackages = ["io.patterueldev.mongods"])
class SingalongServerApplication {
    @Bean
    fun socketIOServer(
        @Value("\${socketio.hostname}") hostname: String,
        @Value("\${socketio.port}") port: Int,
    ): SocketIOServer {
        println("Starting Socket.IO server at $hostname:$port")
        val config = Configuration()
        config.hostname = hostname
        config.port = port
        return SocketIOServer(config)
    }
}

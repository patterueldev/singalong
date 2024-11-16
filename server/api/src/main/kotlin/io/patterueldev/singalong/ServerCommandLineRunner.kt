package io.patterueldev.singalong

import kotlinx.coroutines.runBlocking
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.CommandLineRunner
import org.springframework.context.annotation.Profile
import org.springframework.stereotype.Component

@Component
@Profile("!test")
class ServerCommandLineRunner : CommandLineRunner {
    @Autowired
    private lateinit var singalongService: SingalongService

    @Throws(Exception::class)
    override fun run(vararg args: String) {
        // TODO: This could potentially be done "not-automatically" by the admin
        runBlocking { singalongService.start() }
    }
}

package io.patterueldev.singalong

import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.room.RoomDocumentRepository
import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.role.Role
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.CommandLineRunner
import org.springframework.context.annotation.Profile
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Component

@Component
@Profile("!test")
class DataSeeder : CommandLineRunner {
    @Autowired private lateinit var userDocumentRepository: UserDocumentRepository

    @Autowired private lateinit var roomDocumentRepository: RoomDocumentRepository

    @Autowired private lateinit var passwordEncoder: PasswordEncoder

    override fun run(vararg args: String?) {
        val adminRoomId = "admin" // TODO: Move this to application.properties
        val roomPasscode = "admin" // TODO: Move this to application.properties
        val adminRoom = roomDocumentRepository.findRoomById(adminRoomId)

        if (adminRoom == null) {
            val newAdminRoom =
                RoomDocument(
                    id = adminRoomId,
                    name = "Admin",
                    passcode = passwordEncoder.encode(roomPasscode),
                    archivedAt = null,
                )
            roomDocumentRepository.save(newAdminRoom)
            println("Admin room created")
        } else {
            println("Admin room already exists")
        }

        // create user 'pat' as admin
        val adminUsername = "pat" // TODO: Move this to application.properties
        val userPasscode = "1234" // TODO: Move this to application.properties
        val admin = userDocumentRepository.findByUsername(adminUsername)

        if (admin == null) {
            val newAdmin =
                UserDocument(
                    username = adminUsername,
                    passcode = passwordEncoder.encode(userPasscode),
                    role = Role.ADMIN,
                )
            userDocumentRepository.save(newAdmin)
            println("Admin user created")
        } else {
            println("Admin user already exists")
        }
    }
}

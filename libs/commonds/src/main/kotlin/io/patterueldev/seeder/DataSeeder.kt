package io.patterueldev.seeder

import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.room.RoomDocumentRepository
import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.role.Role
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
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

    @Value("\${singalong.seeders.room.id}")
    private lateinit var roomId: String

    @Value("\${singalong.seeders.room.name}")
    private lateinit var roomName: String

    @Value("\${singalong.seeders.room.passcode}")
    private lateinit var roomPasscode: String

    @Value("\${singalong.seeders.admin.username}")
    private lateinit var adminUsername: String

    @Value("\${singalong.seeders.admin.passcode}")
    private lateinit var adminPasscode: String

    override fun run(vararg args: String?) {
        val adminRoom = roomDocumentRepository.findRoomById(roomId)

        if (adminRoom == null) {
            val newAdminRoom =
                RoomDocument(
                    id = roomId,
                    name = roomName,
                    passcode = passwordEncoder.encode(roomPasscode),
                    archivedAt = null,
                )
            roomDocumentRepository.save(newAdminRoom)
            println("Admin room created")
        } else {
            println("Admin room already exists")
        }

        // create admin user
        val admin = userDocumentRepository.findByUsername(adminUsername)

        if (admin == null) {
            val newAdmin =
                UserDocument(
                    username = adminUsername,
                    passcode = passwordEncoder.encode(adminPasscode),
                    role = Role.ADMIN,
                )
            userDocumentRepository.save(newAdmin)
            println("Admin user created")
        } else {
            println("Admin user already exists")
        }
    }
}

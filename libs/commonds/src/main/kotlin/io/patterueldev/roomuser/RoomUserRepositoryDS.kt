package io.patterueldev.roomuser

import io.patterueldev.authuser.RoomUserDetails
import io.patterueldev.client.ClientType
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.role.Role
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
open class RoomUserRepositoryDS : RoomUserRepository {
    @Autowired private lateinit var userDocumentRepository: UserDocumentRepository

    override suspend fun currentUser(): RoomUser {
        val authentication = SecurityContextHolder.getContext().authentication
        val userDetails = authentication.principal as RoomUserDetails
        val user =
            userDocumentRepository.findByUsername(userDetails.username)
                ?: throw IllegalArgumentException("User not found")
        return object : RoomUser {
            override val username: String = user.username
            override val roomId: String = userDetails.roomId
            override val joinedAt: LocalDateTime = LocalDateTime.now() // doesn't really matter
            override val role: Role = user.role
            override val clientType: ClientType = userDetails.clientType
            override val deviceId: String = userDetails.deviceId
        }
    }
}

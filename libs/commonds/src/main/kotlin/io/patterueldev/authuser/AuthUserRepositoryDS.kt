package io.patterueldev.authuser

import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.role.Role
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service

@Service
class AuthUserRepositoryDS : AuthUserRepository {
    @Autowired private lateinit var userDocumentRepository: UserDocumentRepository

    @Autowired private lateinit var passwordEncoder: PasswordEncoder

    override fun findUserByUsername(username: String): AuthUser? {
        val userDocument: UserDocument = userDocumentRepository.findByUsername(username) ?: return null
        return userDocument.toUser()
    }

    override fun createUser(
        username: String,
        passcode: String?,
        role: Role,
    ): AuthUser {
        val userDocument = UserDocument(username, passcode)
        userDocument.role = role
        userDocumentRepository.save(userDocument)
        return userDocument.toUser()
    }

    override fun updateUser(
        username: String,
        passcode: String?,
        unset: Boolean,
    ): AuthUser {
        var userDocument =
            userDocumentRepository.findByUsername(username)
                ?: throw IllegalArgumentException("User not found")
        if (unset) {
            userDocument.passcode = null
        } else {
            passcode ?: throw IllegalArgumentException("Passcode is required")
            userDocument.passcode = passwordEncoder.encode(passcode)
        }
        userDocument = userDocumentRepository.save(userDocument)
        return userDocument.toUser()
    }

    override fun currentUser(): AuthUser {
        val authentication = SecurityContextHolder.getContext().authentication
        val userDetails = authentication.principal as RoomUserDetails
        return findUserByUsername(userDetails.username)
            ?: throw IllegalArgumentException("User not found")
    }
}

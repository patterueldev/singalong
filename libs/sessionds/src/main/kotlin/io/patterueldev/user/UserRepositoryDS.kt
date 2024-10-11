package io.patterueldev.user

import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.session.auth.AuthUser
import io.patterueldev.session.auth.AuthUserRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service

@Service
class UserRepositoryDS : AuthUserRepository {
    @Autowired private lateinit var userDocumentRepository: UserDocumentRepository

    override fun findUserByUsername(username: String): AuthUser? {
        val userDocument: UserDocument = userDocumentRepository.findByUsername(username) ?: return null
        return userDocument.toUser()
    }

    override fun createUser(
        username: String,
        passcode: String?,
    ): AuthUser {
        val userDocument = UserDocument(username, passcode)
        userDocumentRepository.save(userDocument)
        return userDocument.toUser()
    }

    override fun authenticateUser(
        username: String,
        passcode: String,
    ): String? {
        throw NotImplementedError("Not implemented")
    }
}

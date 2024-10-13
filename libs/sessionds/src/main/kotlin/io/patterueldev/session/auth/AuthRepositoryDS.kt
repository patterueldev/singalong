package io.patterueldev.session.auth

import io.patterueldev.client.ClientType
import io.patterueldev.mongods.room.RoomDocumentRepository
import io.patterueldev.mongods.session.SessionDocument
import io.patterueldev.mongods.session.SessionDocumentRepository
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.session.authuser.AuthUser
import io.patterueldev.session.jwt.JwtUtil
import io.patterueldev.session.room.Room
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service

@Service
class AuthRepositoryDS : AuthRepository {
    @Autowired private lateinit var roomDocumentRepository: RoomDocumentRepository

    @Autowired private lateinit var userDocumentRepository: UserDocumentRepository

    @Autowired private lateinit var sessionDocumentRepository: SessionDocumentRepository

    @Autowired private lateinit var passwordEncoder: PasswordEncoder

    @Autowired private lateinit var jwtUtil: JwtUtil

    override fun matchPasscode(
        plainPasscode: String,
        hashedPasscode: String,
    ): Boolean {
        return passwordEncoder.matches(plainPasscode, hashedPasscode)
    }

    override fun addUserToRoom(
        authUser: AuthUser,
        room: Room,
        clientType: ClientType,
    ): String {
        val userDocument = userDocumentRepository.findByUsername(authUser.username) ?: throw IllegalArgumentException("User not found")
        val roomDocument = roomDocumentRepository.findRoomById(room.id) ?: throw IllegalArgumentException("Room not found")

        sessionDocumentRepository.save(
            SessionDocument(
                userDocument = userDocument,
                roomDocument = roomDocument,
            ),
        )

        // Generate JWT token
        return jwtUtil.generateToken(authUser.username, room.id, clientType)
    }
}

package io.patterueldev.auth

import io.patterueldev.authuser.AuthUser
import io.patterueldev.client.ClientType
import io.patterueldev.jwt.JwtUtil
import io.patterueldev.mongods.room.RoomDocumentRepository
import io.patterueldev.mongods.session.SessionDocument
import io.patterueldev.mongods.session.SessionDocumentRepository
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.room.Room
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import java.time.LocalDateTime

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

    override fun checkUserFromRoom(
        authUser: AuthUser,
        room: Room,
        clientType: ClientType,
    ): UserFromRoom? {
        val userDocument = userDocumentRepository.findByUsername(authUser.username) ?: throw IllegalArgumentException("User not found")
        val roomDocument = roomDocumentRepository.findRoomById(room.id) ?: throw IllegalArgumentException("Room not found")

        println("checkUserFromRoom: $userDocument, $roomDocument")

        val sessionDocument = sessionDocumentRepository.findBy(userDocument.username, roomDocument.id, clientType) ?: return null
        return object : UserFromRoom {
            override val user: AuthUser = authUser
            override val room: Room = room
            override val deviceId: String = sessionDocument.deviceId
            override val lastConnectedAt: LocalDateTime = sessionDocument.lastConnectedAt
            override val isConnected: Boolean = sessionDocument.isConnected
        }
    }

    override fun upsertUserToRoom(
        authUser: AuthUser,
        room: Room,
        clientType: ClientType,
        deviceId: String,
    ): AuthResponse {
        val userDocument = userDocumentRepository.findByUsername(authUser.username) ?: throw IllegalArgumentException("User not found")
        val roomDocument = roomDocumentRepository.findRoomById(room.id) ?: throw IllegalArgumentException("Room not found")

        var sessionDocument = sessionDocumentRepository.findBy(userDocument.username, roomDocument.id, clientType)
        if (sessionDocument == null) {
            sessionDocument =
                SessionDocument(
                    userDocument = userDocument,
                    roomDocument = roomDocument,
                )
        }
        sessionDocument.deviceId = deviceId
        sessionDocument.lastConnectedAt = LocalDateTime.now()
        sessionDocument.isConnected = true
        sessionDocument.connectedOnClient = clientType
        sessionDocumentRepository.save(sessionDocument)

        val role = userDocument.role.name

        // Generate JWT token
        val accessToken = jwtUtil.generateToken(authUser.username, room.id, deviceId, clientType, listOf(role))
        val refreshToken = jwtUtil.generateRefreshToken(authUser.username, room.id, deviceId, clientType, listOf(role))
        return object : AuthResponse {
            override val accessToken: String = accessToken
            override val refreshToken: String = refreshToken
        }
    }
}

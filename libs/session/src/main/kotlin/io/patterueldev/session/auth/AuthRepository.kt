package io.patterueldev.session.auth

import io.patterueldev.client.ClientType
import io.patterueldev.session.authuser.AuthUser
import io.patterueldev.session.room.Room
import java.time.LocalDateTime

interface AuthRepository {
    fun matchPasscode(
        plainPasscode: String,
        hashedPasscode: String,
    ): Boolean

    fun upsertUserToRoom(
        authUser: AuthUser,
        room: Room,
        clientType: ClientType,
        deviceId: String,
    ): AuthResponse

    fun checkUserFromRoom(
        authUser: AuthUser,
        room: Room,
        clientType: ClientType,
    ): UserFromRoom?
}

interface UserFromRoom {
    val user: AuthUser
    val room: Room
    val deviceId: String
    val lastConnectedAt: LocalDateTime
    val isConnected: Boolean
}

interface AuthResponse {
    val accessToken: String
    val refreshToken: String
}

package io.patterueldev.session.reconnect

import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.common.NoParametersUseCase
import io.patterueldev.room.RoomRepository
import io.patterueldev.roomuser.RoomUserRepository

internal class ReconnectUseCase(
    val authUserRepository: AuthUserRepository,
    val roomUserRepository: RoomUserRepository,
    val authRepository: AuthRepository,
    val roomRepository: RoomRepository,
) : NoParametersUseCase<Unit> {
    override suspend fun execute() {
        val user = roomUserRepository.currentUser()
        val authUser = authUserRepository.currentUser()
        val room = roomRepository.findRoomById(user.roomId) ?: throw IllegalArgumentException("Room not found")

        val response = authRepository.upsertUserToRoom(authUser, room, user.clientType, user.deviceId)
        println("ReconnectUseCase: $response")
    }
}

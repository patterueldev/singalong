package io.patterueldev.admin.connectwithroom

import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.client.ClientType
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.room.RoomRepository

internal class ConnectWithRoomUseCase(
    private val roomRepository: RoomRepository,
    private val authUserRepository: AuthUserRepository,
    private val authRepository: AuthRepository,
) : ServiceUseCase<ConnectWithRoomParameters, ConnectWithRoomResponse> {
    override suspend fun execute(parameters: ConnectWithRoomParameters): ConnectWithRoomResponse {
        // step1: find the room
        val room = roomRepository.findRoomById(parameters.roomId) ?: return GenericResponse.failure("Room not found")
        // step1.1: check if the room is archived
        if (room.isArchived) {
            return GenericResponse.failure("Room is archived")
        }

        val adminRoom = roomRepository.findRoomById("admin") ?: return GenericResponse.failure("Admin room not found")
        val admin = authUserRepository.currentUser()
        val userFromRoom =
            authRepository.checkUserFromRoom(admin, adminRoom, ClientType.ADMIN)
                ?: return GenericResponse.failure("User hasn't been in the room yet")
        val response = authRepository.upsertUserToRoom(admin, room, ClientType.ADMIN, userFromRoom.deviceId)
        return GenericResponse.success(
            ConnectWithRoomResponseData(
                accessToken = response.accessToken,
                refreshToken = response.refreshToken,
            ),
        )
    }
}

data class ConnectWithRoomResponseData(
    val accessToken: String,
    val refreshToken: String,
)
typealias ConnectWithRoomResponse = GenericResponse<ConnectWithRoomResponseData>

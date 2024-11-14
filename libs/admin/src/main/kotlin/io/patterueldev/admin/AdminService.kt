package io.patterueldev.admin

import io.patterueldev.admin.connectwithroom.ConnectWithRoomParameters
import io.patterueldev.admin.connectwithroom.ConnectWithRoomUseCase
import io.patterueldev.admin.room.LoadRoomListParameters
import io.patterueldev.admin.room.LoadRoomListUseCase
import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.room.RoomRepository

class AdminService(
    private val roomRepository: RoomRepository,
    private val authRepository: AuthRepository,
    private val authUserRepository: AuthUserRepository,
    private val coordinator: AdminCoordinator? = null,
) {
    private val loadRoomListUseCase: LoadRoomListUseCase by lazy {
        LoadRoomListUseCase(roomRepository)
    }

    private val connectWithRoomUseCase: ConnectWithRoomUseCase by lazy {
        ConnectWithRoomUseCase(roomRepository, authUserRepository, authRepository)
    }

    private val assignPlayerToRoomUseCase: AssignPlayerToRoomUseCase by lazy {
        AssignPlayerToRoomUseCase(roomRepository, authUserRepository, coordinator)
    }

    suspend fun loadRoomList(parameters: LoadRoomListParameters) = loadRoomListUseCase(parameters = parameters)

    suspend fun connectWithRoom(parameters: ConnectWithRoomParameters) = connectWithRoomUseCase(parameters)

    suspend fun assignPlayerToRoom(parameters: AssignPlayerToRoomParameters) = assignPlayerToRoomUseCase(parameters)
}

data class AssignPlayerToRoomParameters(
    val playerId: String,
    val roomId: String,
)

internal class AssignPlayerToRoomUseCase(
    private val roomRepository: RoomRepository,
    private val authUserRepository: AuthUserRepository,
    private val coordinator: AdminCoordinator? = null,
) : ServiceUseCase<AssignPlayerToRoomParameters, GenericResponse<Boolean>> {
    override suspend fun execute(parameters: AssignPlayerToRoomParameters): GenericResponse<Boolean> {
        try {
            println("AssignPlayerToRoomUseCase: $parameters")
            val room = roomRepository.findRoomById(parameters.roomId) ?: return GenericResponse.failure("Room not found")
            val user = authUserRepository.findUserByUsername(parameters.playerId) ?: return GenericResponse.failure("User not found")

            println("Assigning player to room: $user, $room")
            roomRepository.assignPlayerToRoom(user.username, room.id)

            coordinator?.onAssignedPlayerToRoom(user.username, room.id)

            println("Assigned player to room: $user, $room")
            return GenericResponse.success(true)
        } catch (e: Exception) {
            e.printStackTrace()
            return GenericResponse.failure("Error assigning player to room: $e")
        }
    }
}

interface AdminCoordinator {
    fun onAssignedPlayerToRoom(
        playerId: String,
        roomId: String,
    )
}

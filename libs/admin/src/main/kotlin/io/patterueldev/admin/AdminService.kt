package io.patterueldev.admin

import io.patterueldev.admin.assignplayertoroom.AssignPlayerToRoomParameters
import io.patterueldev.admin.assignplayertoroom.AssignPlayerToRoomUseCase
import io.patterueldev.admin.connectwithroom.ConnectWithRoomParameters
import io.patterueldev.admin.connectwithroom.ConnectWithRoomUseCase
import io.patterueldev.admin.room.LoadRoomListParameters
import io.patterueldev.admin.room.LoadRoomListUseCase
import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.room.CreateRoomParameters
import io.patterueldev.room.Room
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

    private val createRoomUseCase: CreateRoomUseCase by lazy {
        CreateRoomUseCase(roomRepository)
    }

    suspend fun loadRoomList(parameters: LoadRoomListParameters) = loadRoomListUseCase(parameters = parameters)

    suspend fun connectWithRoom(parameters: ConnectWithRoomParameters) = connectWithRoomUseCase(parameters)

    suspend fun assignPlayerToRoom(parameters: AssignPlayerToRoomParameters) = assignPlayerToRoomUseCase(parameters)

    suspend fun newRoomId(): GenericResponse<String> = GenericResponse.success(roomRepository.newRoomId())

    suspend fun createRoom(parameters: CreateRoomParameters): CreateRoomResponse = createRoomUseCase(parameters)
}

internal class CreateRoomUseCase(
    private val roomRepository: RoomRepository,
) : ServiceUseCase<CreateRoomParameters, CreateRoomResponse> {
    override suspend fun execute(parameters: CreateRoomParameters): CreateRoomResponse {
        try {
            val result = roomRepository.createRoom(parameters)
            return GenericResponse.success(result)
        } catch (e: Exception) {
            return GenericResponse.failure(e.message ?: "Failed to create room")
        }
    }
}

typealias CreateRoomResponse = GenericResponse<Room>

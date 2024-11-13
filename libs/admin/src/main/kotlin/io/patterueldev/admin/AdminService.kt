package io.patterueldev.admin

import io.patterueldev.admin.connectwithroom.ConnectWithRoomParameters
import io.patterueldev.admin.connectwithroom.ConnectWithRoomUseCase
import io.patterueldev.admin.room.LoadRoomListParameters
import io.patterueldev.admin.room.LoadRoomListUseCase
import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.room.RoomRepository

class AdminService(
    private val roomRepository: RoomRepository,
    private val authRepository: AuthRepository,
    private val authUserRepository: AuthUserRepository,
) {
    private val loadRoomListUseCase: LoadRoomListUseCase by lazy {
        LoadRoomListUseCase(roomRepository)
    }

    private val connectWithRoomUseCase: ConnectWithRoomUseCase by lazy {
        ConnectWithRoomUseCase(roomRepository, authUserRepository, authRepository)
    }

    suspend fun loadRoomList(parameters: LoadRoomListParameters) = loadRoomListUseCase(parameters = parameters)

    suspend fun connectWithRoom(parameters: ConnectWithRoomParameters) = connectWithRoomUseCase(parameters)
}

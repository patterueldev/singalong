package io.patterueldev.admin

import io.patterueldev.admin.room.LoadRoomListParameters
import io.patterueldev.admin.room.LoadRoomListUseCase
import io.patterueldev.room.RoomRepository

class AdminService(
    private val roomRepository: RoomRepository,
) {
    private val loadRoomListUseCase: LoadRoomListUseCase by lazy {
        LoadRoomListUseCase(roomRepository)
    }

    suspend fun loadRoomList(parameters: LoadRoomListParameters) = loadRoomListUseCase(parameters = parameters)
}

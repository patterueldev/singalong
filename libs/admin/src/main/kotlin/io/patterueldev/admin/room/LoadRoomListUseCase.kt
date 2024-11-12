package io.patterueldev.admin.room

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.room.RoomRepository

internal class LoadRoomListUseCase(
    private val roomRepository: RoomRepository,
) : ServiceUseCase<LoadRoomListParameters, LoadRoomListResponse> {
    override suspend fun execute(parameters: LoadRoomListParameters): LoadRoomListResponse {
        return try {
            parameters.validate()
            val rooms = roomRepository.loadRoomList(parameters.limit, parameters.keyword, parameters.nextPage())
            GenericResponse.success(rooms)
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading songs.")
        }
    }
}

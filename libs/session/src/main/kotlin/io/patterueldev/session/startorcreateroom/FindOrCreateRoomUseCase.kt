package io.patterueldev.session.startorcreateroom

import io.patterueldev.common.GenericNoParametersUseCase
import io.patterueldev.common.GenericResponse
import io.patterueldev.session.room.Room
import io.patterueldev.session.room.RoomRepository

internal class FindOrCreateRoomUseCase(
    val roomRepository: RoomRepository,
) : GenericNoParametersUseCase<Room> {
    override suspend fun execute(): GenericResponse<Room> {
        try {
            // get last active room that is not admin
            var lastActiveRoom = roomRepository.findActiveRoom()
            if (lastActiveRoom == null) {
                lastActiveRoom = roomRepository.createRoom()
                println("Created room: $lastActiveRoom")
            }
            return GenericResponse.success(lastActiveRoom)
        } catch (e: Exception) {
            return GenericResponse.failure(e.message ?: "An error occurred while starting or creating a room.")
        }
    }
}

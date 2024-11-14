package io.patterueldev.admin.assign_player_to_room

import io.patterueldev.admin.AdminCoordinator
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.room.RoomRepository

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
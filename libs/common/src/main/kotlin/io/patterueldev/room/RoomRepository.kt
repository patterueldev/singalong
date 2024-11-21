package io.patterueldev.room

import io.patterueldev.common.Pagination
import io.patterueldev.room.createroom.CreateRoomParameters
import io.patterueldev.roomuser.RoomUser

interface RoomRepository {
    suspend fun newRoomId(): String

    suspend fun findRoomById(roomId: String): Room?

    suspend fun findActiveRoom(): Room?

    suspend fun findActiveRooms(): List<Room>

    suspend fun findAssignedRoomForPlayer(playerId: String): Room?

    suspend fun createRoom(parameters: CreateRoomParameters? = null): Room

    suspend fun loadRoomList(
        limit: Int,
        keyword: String?,
        page: Pagination?,
    ): PaginatedRoomList

    suspend fun assignPlayerToRoom(
        playerId: String,
        roomId: String,
    )

    suspend fun getUsersInRoom(roomId: String): List<RoomUser>
}

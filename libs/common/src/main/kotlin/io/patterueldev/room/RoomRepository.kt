package io.patterueldev.room

import io.patterueldev.common.Pagination

interface RoomRepository {
    suspend fun newRoomId(): String

    suspend fun findRoomById(roomId: String): Room?

    suspend fun findActiveRoom(): Room?

    suspend fun createRoom(): Room

    suspend fun loadRoomList(
        limit: Int,
        keyword: String?,
        page: Pagination?,
    ): PaginatedRoomList

    suspend fun assignPlayerToRoom(
        playerId: String,
        roomId: String,
    )
}

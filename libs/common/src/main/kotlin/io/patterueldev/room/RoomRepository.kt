package io.patterueldev.room

import io.patterueldev.common.Pagination

interface RoomRepository {
    fun findRoomById(roomId: String): Room?

    fun findActiveRoom(): Room?

    fun createRoom(): Room

    suspend fun loadRoomList(
        limit: Int,
        keyword: String?,
        page: Pagination?,
    ): PaginatedRoomList
}

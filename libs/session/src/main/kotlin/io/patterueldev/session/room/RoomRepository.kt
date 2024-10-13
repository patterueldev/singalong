package io.patterueldev.session.room

interface RoomRepository {
    fun findRoomById(roomId: String): Room?

    fun findActiveRoom(): Room?

    fun createRoom(): Room
}

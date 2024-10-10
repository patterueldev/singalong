package io.patterueldev.session.room

interface RoomRepository {
    fun findRoomById(roomId: String): Room?
}
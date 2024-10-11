package io.patterueldev.roomuser

interface RoomUserRepository {
    fun currentUser(): RoomUser
}
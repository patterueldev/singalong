package io.patterueldev.roomuser

interface RoomUserRepository {
    suspend fun currentUser(): RoomUser
}

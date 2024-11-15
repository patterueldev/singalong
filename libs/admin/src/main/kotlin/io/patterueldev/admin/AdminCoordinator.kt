package io.patterueldev.admin

interface AdminCoordinator {
    fun onAssignedPlayerToRoom(
        playerId: String,
        roomId: String,
    )
}

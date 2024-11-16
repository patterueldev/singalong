package io.patterueldev.reservation

interface ReservationCoordinator {
    fun onReserveUpdate(roomId: String)

    fun onCurrentSongUpdate(roomId: String)
}

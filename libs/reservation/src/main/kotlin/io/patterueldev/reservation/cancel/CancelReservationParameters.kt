package io.patterueldev.reservation.cancel

data class CancelReservationParameters(
    val roomId: String,
    val reservedSongId: String,
)
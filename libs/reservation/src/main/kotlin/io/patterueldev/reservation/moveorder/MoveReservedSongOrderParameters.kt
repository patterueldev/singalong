package io.patterueldev.reservation.moveorder

data class MoveReservedSongOrderParameters(
    val roomId: String,
    val reservedSongId: String,
    val newOrder: Int,
)
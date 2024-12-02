package io.patterueldev.room.createroom

data class CreateRoomParameters(
    val roomId: String,
    val roomName: String,
    val roomPasscode: String = "",
)

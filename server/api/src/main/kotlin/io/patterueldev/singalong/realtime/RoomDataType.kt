package io.patterueldev.singalong.realtime

enum class RoomDataType(val value: String) {
    RESERVED_SONGS("reservedSongs"),
    CURRENT_SONG("currentSong"),
    PLAYER_LIST("playerList"),
    ALL("all"),
    ;

    companion object {
        fun fromString(value: String): RoomDataType {
            return entries.first { it.value == value }
        }
    }
}

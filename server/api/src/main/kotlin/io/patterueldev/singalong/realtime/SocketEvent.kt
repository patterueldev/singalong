package io.patterueldev.singalong.realtime

enum class SocketEvent(val value: String) {
    ROOM_DATA_REQUEST("roomDataRequest"),
    RESERVED_SONGS("reservedSongs"),
    CURRENT_SONG("currentSong"),
    ROOM_PLAYER_COMMAND("roomPlayerCommand"),
    DURATION_UPDATE("durationUpdate"),
    SEEK_DURATION("seekDuration"),
    TOGGLE_PLAY_PAUSE("togglePlayPause"),
    SKIP_SONG("skipSong"),
    CONNECTED("connected"),
    DISCONNECTED("disconnected"),
    ERROR("error"),
    USER_JOINED("userJoined"),
    USER_LEFT("userLeft"),
    ADJUST_VOLUME_FROM_CONTROL("adjustVolumeFromControl"),
    PLAYERS_LIST("playersList"),
    ROOM_ASSIGNED("roomAssigned"),
}

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

enum class RoomCommandType(val value: String) {
    SKIP_SONG("skipSong"),
    TOGGLE_PLAY_PAUSE("togglePlayPause"),
    ADJUST_VOLUME("adjustVolume"),
    DURATION_UPDATE("durationUpdate"),
    SEEK_DURATION("seekDuration"),
    ;

    companion object {
        fun fromString(value: String): RoomCommandType {
            return entries.first { it.value == value }
        }
    }
}

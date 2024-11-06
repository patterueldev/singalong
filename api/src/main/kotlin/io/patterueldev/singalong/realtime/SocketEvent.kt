package io.patterueldev.singalong.realtime

enum class SocketEvent(val value: String) {
    RESERVED_SONGS("reservedSongs"),
    CURRENT_SONG("currentSong"),
    SONG_PLAYED("songPlayed"),
    SONG_PAUSED("songPaused"),
    CONNECTED("connected"),
    DISCONNECTED("disconnected"),
    ERROR("error"),
    USER_JOINED("userJoined"),
    USER_LEFT("userLeft"),
    SEEK_DURATION("seekDuration"),
    SEEK("seek"),
}

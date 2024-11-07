package io.patterueldev.singalong.realtime

enum class SocketEvent(val value: String) {
    RESERVED_SONGS("reservedSongs"),
    CURRENT_SONG("currentSong"),
    SEEK_DURATION_FROM_PLAYER("seekDurationFromPlayer"),
    SEEK_DURATION_FROM_CONTROL("seekDurationFromControl"),
    PAUSE_SONG("pauseSong"),
    PLAY_SONG("playSong"),
    SKIP_SONG("skipSong"),
    CONNECTED("connected"),
    DISCONNECTED("disconnected"),
    ERROR("error"),
    USER_JOINED("userJoined"),
    USER_LEFT("userLeft"),
}
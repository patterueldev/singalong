package io.patterueldev.singalong.realtime

enum class SocketEvent(val value: String) {
    IDLE_RECONNECT_ATTEMPT("idleReconnectAttempt"),
    ROOM_DATA_REQUEST("roomDataRequest"),
    RESERVED_SONGS("reservedSongs"),
    CURRENT_SONG("currentSong"),
    ROOM_PLAYER_COMMAND("roomPlayerCommand"),
    DURATION_UPDATE("durationUpdate"),
    SEEK_DURATION("seekDuration"),
    TOGGLE_PLAY_PAUSE("togglePlayPause"),
    ADJUST_VOLUME_FROM_CONTROL("adjustVolumeFromControl"),
    PLAYERS_LIST("playersList"),
    ROOM_ASSIGNED("roomAssigned"),
    PLAYER_ASSIGNED("playerAssigned"),
    PARTICIPANTS_LIST("participantsList"),
}

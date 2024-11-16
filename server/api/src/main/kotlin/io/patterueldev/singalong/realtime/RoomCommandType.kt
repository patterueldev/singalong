package io.patterueldev.singalong.realtime

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

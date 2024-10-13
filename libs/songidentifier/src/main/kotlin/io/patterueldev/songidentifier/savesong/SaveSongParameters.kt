package io.patterueldev.songidentifier.savesong

import io.patterueldev.songidentifier.common.IdentifiedSong

data class SaveSongParameters(
    val song: IdentifiedSong,
    val thenReserve: Boolean,
)

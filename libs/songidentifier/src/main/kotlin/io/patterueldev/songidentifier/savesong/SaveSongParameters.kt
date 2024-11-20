package io.patterueldev.songidentifier.savesong

import io.patterueldev.identifysong.IdentifiedSong

data class SaveSongParameters(
    val song: IdentifiedSong,
    val thenReserve: Boolean,
)

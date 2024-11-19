package io.patterueldev.songbook.songdetails

data class LoadSongDetailsParameters(
    val songId: String,
    val roomId: String? = null,
)

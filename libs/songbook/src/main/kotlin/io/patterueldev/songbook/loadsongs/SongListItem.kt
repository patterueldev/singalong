package io.patterueldev.songbook.loadsongs

data class SongListItem(
    val id: String,
    val thumbnailPath: String,
    val title: String,
    val artist: String,
    val language: String,
    val isOffVocal: Boolean,
    val lengthSeconds: Int,
)

package io.patterueldev.songbook.updatesong

data class UpdateSongParameters(
    val songId: String,
    val title: String,
    val artist: String,
    val language: String,
    val isOffVocal: Boolean,
    val videoHasLyrics: Boolean,
    val songLyrics: String,
    val metadata: Map<String, String>,
    val genres: List<String>,
    val tags: List<String>,
)

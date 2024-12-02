package io.patterueldev.identifysong

// This is a bit japanese-biased, so we can add more languages and genres
data class EnhancedSong(
    val originalTitle: String?,
    val artist: String?,
    val language: String?,
    val genres: List<String>?,
    val romanizedTitle: String?,
    val englishTitle: String?,
    val relevantTags: List<String>?,
    val isOffVocal: Boolean?,
    val videoHasLyrics: Boolean?,
)

package io.patterueldev.song

interface Song {
    val id: String
    val filename: String
    val source: String
    val imageUrl: String
    val songTitle: String
    val songArtist: String
    val songLanguage: String
    val isOffVocal: Boolean
    val videoHasLyrics: Boolean
    val songLyrics: String
    val lengthSeconds: Int
}
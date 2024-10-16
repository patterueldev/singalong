package io.patterueldev.songidentifier.common

interface SavedSong {
    val id: String
    val source: String
    val thumbnailPath: String
    val videoPath: String?
    val songTitle: String
    val songArtist: String
    val songLanguage: String
    val isOffVocal: Boolean
    val videoHasLyrics: Boolean
    val songLyrics: String
    val lengthSeconds: Int
}

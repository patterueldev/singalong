package io.patterueldev.songbook.songdetails

interface SongDetails {
    val id: String
    val source: String
    val title: String
    val artist: String
    val language: String
    val isOffVocal: Boolean
    val videoHasLyrics: Boolean
    val duration: Int
    val genres: List<String>
    val tags: List<String>
    val metadata: Map<String, String>
    val thumbnailPath: String
    val wasReserved: Boolean
    val currentPlaying: Boolean
    val lyrics: String?
    val addedBy: String
    val addedAtSession: String
    val lastUpdatedBy: String
    val isCorrupted: Boolean
}

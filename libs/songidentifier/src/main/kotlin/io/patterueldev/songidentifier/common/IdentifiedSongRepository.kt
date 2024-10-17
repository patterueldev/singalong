package io.patterueldev.songidentifier.common

interface IdentifiedSongRepository {
    suspend fun identifySong(url: String): IdentifiedSong?

    suspend fun enhanceSong(identifiedSong: IdentifiedSong): IdentifiedSong

    suspend fun saveSong(
        identifiedSong: IdentifiedSong,
        userId: String,
        sessionId: String,
    ): SavedSong

    suspend fun downloadThumbnail(
        song: SavedSong,
        imageUrl: String,
        fileTitle: String,
    ): SavedSong

    suspend fun updateSong(
        songId: String,
        filename: String,
    ): SavedSong


    suspend fun downloadSong(
        song: SavedSong,
        sourceUrl: String,
        fileTitle: String,
    ): SavedSong

    suspend fun reserveSong(
        songId: String,
        sessionId: String,
    )
}

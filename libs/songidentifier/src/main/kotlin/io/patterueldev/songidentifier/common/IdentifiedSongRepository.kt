package io.patterueldev.songidentifier.common

interface IdentifiedSongRepository {
    suspend fun identifySong(url: String): IdentifiedSong?

    suspend fun enhanceSong(identifiedSong: IdentifiedSong): IdentifiedSong

    suspend fun saveSong(
        identifiedSong: IdentifiedSong,
        userId: String,
        sessionId: String,
    ): String

    suspend fun downloadSong(
        url: String,
        filename: String,
    )

    suspend fun updateSong(
        songId: String,
        filename: String,
    )

    suspend fun reserveSong(
        songId: String,
        sessionId: String,
    )
}

package io.patterueldev.songidentifier.common

import io.patterueldev.songidentifier.searchsong.SearchResultItem

interface IdentifiedSongRepository {
    suspend fun identifySong(url: String): IdentifiedSong?

    suspend fun getExistingSong(identifiedSong: IdentifiedSong): IdentifiedSong?

    suspend fun enhanceSong(identifiedSong: IdentifiedSong): IdentifiedSong

    suspend fun saveSong(
        identifiedSong: IdentifiedSong,
        userId: String,
        sessionId: String,
    ): SavedSong

    suspend fun downloadThumbnail(
        song: SavedSong,
        imageUrl: String,
        filename: String,
    ): SavedSong

    suspend fun updateSong(
        songId: String,
        filename: String,
    ): SavedSong

    suspend fun downloadSong(
        song: SavedSong,
        sourceUrl: String,
        filename: String,
    ): SavedSong

    suspend fun reserveSong(
        songId: String,
        sessionId: String,
    )

    suspend fun searchSongs(keyword: String): List<SearchResultItem>
}

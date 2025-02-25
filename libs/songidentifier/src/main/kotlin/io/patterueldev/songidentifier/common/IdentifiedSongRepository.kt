package io.patterueldev.songidentifier.common

import io.patterueldev.common.BucketFile
import io.patterueldev.identifysong.IdentifiedSong
import io.patterueldev.reservedsong.ReservedSong
import io.patterueldev.roomuser.RoomUser
import io.patterueldev.songidentifier.searchsong.SearchResultItem

interface IdentifiedSongRepository {
    suspend fun identifySong(url: String): IdentifiedSong?

    suspend fun getExistingSong(identifiedSong: IdentifiedSong): IdentifiedSong?

    suspend fun enhanceSong(identifiedSong: IdentifiedSong): IdentifiedSong

    suspend fun songAlreadyDownloaded(sourceId: String): Boolean

    suspend fun downloadSongVideo(
        sourceUrl: String,
        filename: String,
    ): BucketFile

    suspend fun downloadSongThumbnail(
        imageUrl: String,
        filename: String,
    ): BucketFile

    suspend fun saveSong(
        identifiedSong: IdentifiedSong,
        userId: String,
        sessionId: String,
        videoFile: BucketFile,
        thumbnailFile: BucketFile,
    ): SavedSong

    suspend fun updateSong(
        songId: String,
        filename: String,
    ): SavedSong

    suspend fun reserveSong(
        roomUser: RoomUser,
        songId: String,
    ): ReservedSong

    suspend fun searchSongs(
        keyword: String,
        limit: Int,
    ): List<SearchResultItem>
}

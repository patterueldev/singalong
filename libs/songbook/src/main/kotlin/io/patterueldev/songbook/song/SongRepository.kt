package io.patterueldev.songbook.song

import io.patterueldev.common.BucketFile
import io.patterueldev.common.Pagination
import io.patterueldev.songbook.loadsongs.PaginatedSongs
import io.patterueldev.songbook.loadsongs.SongbookItem
import io.patterueldev.songbook.songdetails.SongDetails
import io.patterueldev.songbook.updatesong.UpdateSongParameters

interface SongRepository {
    suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
        filteringIds: List<String> = emptyList(),
    ): PaginatedSongs

    // makes sense to return songs instead of reservations; I can use the data for recommendations and stuff
    suspend fun loadReservedSongs(roomId: String): List<SongbookItem>

    suspend fun loadSongDetails(
        id: String,
        roomId: String?,
    ): SongDetails?

    suspend fun updateSongDetails(parameters: UpdateSongParameters): SongDetails

    suspend fun isReservedOrPlaying(songId: String): Boolean

    suspend fun wasReserved(songId: String): Boolean

    suspend fun getSongRecord(songId: String): SongRecord?

    suspend fun getSongsBySourceId(sourceId: String): List<SongRecord>

    suspend fun deleteSongFile(bucketFile: BucketFile?)

    suspend fun deleteSong(songId: String)

    suspend fun archiveSong(songId: String)
}

interface SongRecord {
    val id: String
    val sourceId: String
    val thumbnailFile: BucketFile
    val videoFile: BucketFile?
}

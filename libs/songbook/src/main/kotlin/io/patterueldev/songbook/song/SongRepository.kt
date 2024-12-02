package io.patterueldev.songbook.song

import io.patterueldev.common.BucketFile
import io.patterueldev.common.Pagination
import io.patterueldev.roomuser.RoomUser
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
    suspend fun loadReservedSongsInRoom(roomId: String): List<SongbookItem>

    suspend fun loadSongDetails(
        id: String,
        roomId: String?,
    ): SongDetails?

    suspend fun updateSongDetails(
        parameters: UpdateSongParameters,
        by: RoomUser,
    ): SongDetails

    suspend fun isPlayingOrAboutToPlay(songId: String): Boolean

    suspend fun wasReserved(songId: String): Boolean

    suspend fun getSongRecord(songId: String): SongRecord?

    suspend fun getSongsBySourceId(sourceId: String): List<SongRecord>

    suspend fun deleteSongFile(bucketFile: BucketFile?)

    suspend fun deleteSong(songId: String)

    suspend fun archiveSong(songId: String)

    suspend fun enhanceSong(songId: String): SongDetails
}

interface SongRecord {
    val id: String
    val sourceId: String
    val thumbnailFile: BucketFile
    val videoFile: BucketFile?
}

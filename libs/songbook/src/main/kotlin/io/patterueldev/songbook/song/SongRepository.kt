package io.patterueldev.songbook.song

import io.patterueldev.common.Pagination
import io.patterueldev.songbook.loadsongs.PaginatedSongs
import io.patterueldev.songbook.loadsongs.SongListItem

interface SongRepository {
    suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
        filteringIds: List<String> = emptyList(),
    ): PaginatedSongs

    // makes sense to return songs instead of reservations; I can use the data for recommendations and stuff
    suspend fun loadReservedSongs(roomId: String): List<SongListItem>
}

package io.patterueldev.songbook.song

import io.patterueldev.common.Pagination
import io.patterueldev.songbook.loadsongs.PaginatedSongs

interface SongRepository {
    suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
    ): PaginatedSongs
}

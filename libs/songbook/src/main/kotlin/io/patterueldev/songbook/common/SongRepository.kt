package io.patterueldev.songbook.common

import io.patterueldev.shared.Pagination
import io.patterueldev.songbook.loadsongs.PaginatedSongs

interface SongRepository {
    suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
    ): PaginatedSongs
}

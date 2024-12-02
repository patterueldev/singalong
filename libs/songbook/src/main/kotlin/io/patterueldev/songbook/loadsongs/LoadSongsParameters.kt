package io.patterueldev.songbook.loadsongs

import io.patterueldev.common.Pagination

data class LoadSongsParameters(
    val limit: Int = 20,
    val keyword: String? = null,
    val offset: Int? = null,
    val cursor: String? = null,
    val page: Int? = null,
    val roomId: String? = null,
) {
    fun validate() {
        val nonNullCount = listOf(offset, cursor, page).count { it != null }
        require(nonNullCount <= 1) { "Only one of offset, cursor, or page should be non-null." }
    }

    fun recommendation(): Boolean = keyword.isNullOrBlank() && !roomId.isNullOrBlank()

    override fun toString(): String {
        return "LoadSongsParameters(limit=$limit, keyword=$keyword, offset=$offset, cursor=$cursor, page=$page, roomId=$roomId)"
    }

    fun nextPage(): Pagination? {
        return if (offset != null) {
            Pagination.OffsetPagination(offset)
        } else if (cursor != null) {
            Pagination.CursorPagination(cursor)
        } else if (page != null) {
            Pagination.PagePagination(page)
        } else {
            null
        }
    }
}

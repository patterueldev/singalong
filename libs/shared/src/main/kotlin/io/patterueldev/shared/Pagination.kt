package io.patterueldev.shared

sealed class Pagination {
    data class OffsetPagination(val nextOffset: Int) : Pagination()
    data class CursorPagination(val nextCursor: String) : Pagination()
    data class PagePagination(val pageNumber: Int) : Pagination() // Limit can be set externally
    object NoMorePages : Pagination()
}
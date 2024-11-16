package io.patterueldev.common

open class PaginatedData<T>(
    val count: Int,
    val items: List<T>,
    val nextOffset: Int?,
    val nextCursor: String?,
    val nextPage: Int?,
) {
    companion object {
        fun <T> empty(): PaginatedData<T> {
            return PaginatedData(0, emptyList(), null, null, null)
        }

        fun <T> lastPage(data: List<T>): PaginatedData<T> {
            return PaginatedData(data.size, data, null, null, null)
        }

        fun <T> withNextOffset(
            data: List<T>,
            nextOffset: Int,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, nextOffset, null, null)
        }

        fun <T> withNextCursor(
            data: List<T>,
            nextCursor: String,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, null, nextCursor, null)
        }

        fun <T> withNextPage(
            data: List<T>,
            nextPage: Int,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, null, null, nextPage)
        }
    }
}

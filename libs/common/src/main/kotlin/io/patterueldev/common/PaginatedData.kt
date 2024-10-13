package io.patterueldev.common

open class PaginatedData<T>(
    val data: List<T>,
    val nextOffset: Int?,
    val nextCursor: String?,
    val nextPage: Int?,
) {
    companion object {
        fun <T> empty(): PaginatedData<T> {
            return PaginatedData(emptyList(), null, null, null)
        }

        fun <T> lastPage(data: List<T>): PaginatedData<T> {
            return PaginatedData(data, null, null, null)
        }

        fun <T> withNextOffset(
            data: List<T>,
            nextOffset: Int,
        ): PaginatedData<T> {
            return PaginatedData(data, nextOffset, null, null)
        }

        fun <T> withNextCursor(
            data: List<T>,
            nextCursor: String,
        ): PaginatedData<T> {
            return PaginatedData(data, null, nextCursor, null)
        }

        fun <T> withNextPage(
            data: List<T>,
            nextPage: Int,
        ): PaginatedData<T> {
            return PaginatedData(data, null, null, nextPage)
        }
    }
}

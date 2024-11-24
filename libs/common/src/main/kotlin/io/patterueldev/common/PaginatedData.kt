package io.patterueldev.common

open class PaginatedData<T>(
    val count: Int,
    val items: List<T>,
    val nextOffset: Int?,
    val nextCursor: String?,
    val nextPage: Int?,
    val totalItems: Int?,
    val totalPages: Int?,
) {
    fun shuffled(): PaginatedData<T> {
        return PaginatedData(count, items.shuffled(), nextOffset, nextCursor, nextPage, totalItems, totalPages)
    }

    companion object {
        fun <T> empty(): PaginatedData<T> {
            return PaginatedData(0, emptyList(), null, null, null, null, null)
        }

        fun <T> lastPage(
            data: List<T>,
            totalItems: Int,
            totalPages: Int,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, null, null, null, totalItems, totalPages)
        }

        fun <T> withNextOffset(
            data: List<T>,
            nextOffset: Int,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, nextOffset, null, null, null, null)
        }

        fun <T> withNextCursor(
            data: List<T>,
            nextCursor: String,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, null, nextCursor, null, null, null)
        }

        fun <T> withNextPage(
            data: List<T>,
            nextPage: Int,
            totalItems: Int,
            totalPages: Int,
        ): PaginatedData<T> {
            return PaginatedData(data.size, data, null, null, nextPage, totalItems, totalPages)
        }
    }
}

package io.patterueldev.common

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class PaginatedDataTest {
    @Test
    fun empty_returnsEmptyPaginatedData() {
        val result = PaginatedData.empty<String>()
        assertTrue(result.items.isEmpty())
        assertNull(result.nextOffset)
        assertNull(result.nextCursor)
        assertNull(result.nextPage)
    }

    @Test
    fun lastPage_returnsPaginatedDataWithNoNextPage() {
        val data = listOf("item1", "item2")
        val result = PaginatedData.lastPage(data)
        assertEquals(data, result.items)
        assertNull(result.nextOffset)
        assertNull(result.nextCursor)
        assertNull(result.nextPage)
    }

    @Test
    fun withNextOffset_returnsPaginatedDataWithNextOffset() {
        val data = listOf("item1", "item2")
        val nextOffset = 10
        val result = PaginatedData.withNextOffset(data, nextOffset)
        assertEquals(data, result.items)
        assertEquals(nextOffset, result.nextOffset)
        assertNull(result.nextCursor)
        assertNull(result.nextPage)
    }

    @Test
    fun withNextCursor_returnsPaginatedDataWithNextCursor() {
        val data = listOf("item1", "item2")
        val nextCursor = "cursor123"
        val result = PaginatedData.withNextCursor(data, nextCursor)
        assertEquals(data, result.items)
        assertNull(result.nextOffset)
        assertEquals(nextCursor, result.nextCursor)
        assertNull(result.nextPage)
    }

    @Test
    fun withNextPage_returnsPaginatedDataWithNextPage() {
        val data = listOf("item1", "item2")
        val nextPage = 2
        val result = PaginatedData.withNextPage(data, nextPage)
        assertEquals(data, result.items)
        assertNull(result.nextOffset)
        assertNull(result.nextCursor)
        assertEquals(nextPage, result.nextPage)
    }
}

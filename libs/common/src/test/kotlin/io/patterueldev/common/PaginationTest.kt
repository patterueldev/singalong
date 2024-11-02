package io.patterueldev.common

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class PaginationTest {
    @Test
    fun offsetPagination_createsCorrectInstance() {
        val nextOffset = 10
        val pagination = Pagination.OffsetPagination(nextOffset)
        assertEquals(nextOffset, pagination.nextOffset)
    }

    @Test
    fun cursorPagination_createsCorrectInstance() {
        val nextCursor = "cursor123"
        val pagination = Pagination.CursorPagination(nextCursor)
        assertEquals(nextCursor, pagination.nextCursor)
    }

    @Test
    fun pagePagination_createsCorrectInstance() {
        val pageNumber = 2
        val pagination = Pagination.PagePagination(pageNumber)
        assertEquals(pageNumber, pagination.pageNumber)
    }

    @Test
    fun noMorePages_createsCorrectInstance() {
        val pagination = Pagination.NoMorePages
        assertTrue(pagination is Pagination.NoMorePages)
    }
}

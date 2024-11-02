package io.patterueldev.roomuser

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class RoomUserTest {
    class TestRoomUser(override val username: String, override val roomId: String) : RoomUser

    @Test
    fun roomUser_withValidUsernameAndRoomId_returnsCorrectValues() {
        val roomUser = TestRoomUser("user1", "room1")
        assertEquals("user1", roomUser.username)
        assertEquals("room1", roomUser.roomId)
    }

    @Test
    fun roomUser_withEmptyUsername_returnsEmptyUsername() {
        val roomUser = TestRoomUser("", "room1")
        assertEquals("", roomUser.username)
        assertEquals("room1", roomUser.roomId)
    }

    @Test
    fun roomUser_withEmptyRoomId_returnsEmptyRoomId() {
        val roomUser = TestRoomUser("user1", "")
        assertEquals("user1", roomUser.username)
        assertEquals("", roomUser.roomId)
    }

    @Test
    fun roomUser_withEmptyUsernameAndRoomId_returnsEmptyValues() {
        val roomUser = TestRoomUser("", "")
        assertEquals("", roomUser.username)
        assertEquals("", roomUser.roomId)
    }
}

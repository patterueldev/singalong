package io.patterueldev.roomuser

import io.patterueldev.client.ClientType
import io.patterueldev.role.Role
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import java.time.LocalDateTime

class RoomUserRepositoryTest {
    class TestRoomUserRepository(private val roomUser: RoomUser) : RoomUserRepository {
        override suspend fun currentUser(): RoomUser = roomUser
    }

    @Test
    fun currentUser_returnsValidRoomUser() =
        runBlocking {
            val roomUser =
                object : RoomUser {
                    override val username = "user1"
                    override val roomId = "room1"
                    override val joinedAt: LocalDateTime = LocalDateTime.now()
                    override val role: Role = Role.USER_GUEST
                    override val clientType: ClientType = ClientType.CONTROLLER
                    override val deviceId: String = "device1"
                }
            val repository = TestRoomUserRepository(roomUser)
            val result = repository.currentUser()
            assertEquals("user1", result.username)
            assertEquals("room1", result.roomId)
        }

    @Test
    fun currentUser_withEmptyUsername_returnsRoomUserWithEmptyUsername() =
        runBlocking {
            val roomUser =
                object : RoomUser {
                    override val username = ""
                    override val roomId = "room1"
                    override val joinedAt: LocalDateTime = LocalDateTime.now()
                    override val role: Role = Role.USER_GUEST
                    override val clientType: ClientType = ClientType.CONTROLLER
                    override val deviceId: String = "device1"
                }
            val repository = TestRoomUserRepository(roomUser)
            val result = repository.currentUser()
            assertEquals("", result.username)
            assertEquals("room1", result.roomId)
        }

    @Test
    fun currentUser_withEmptyRoomId_returnsRoomUserWithEmptyRoomId() =
        runBlocking {
            val roomUser =
                object : RoomUser {
                    override val username = "user1"
                    override val roomId = ""
                    override val joinedAt: LocalDateTime = LocalDateTime.now()
                    override val role: Role = Role.USER_GUEST
                    override val clientType: ClientType = ClientType.CONTROLLER
                    override val deviceId: String = "device1"
                }
            val repository = TestRoomUserRepository(roomUser)
            val result = repository.currentUser()
            assertEquals("user1", result.username)
            assertEquals("", result.roomId)
        }

    @Test
    fun currentUser_withEmptyUsernameAndRoomId_returnsRoomUserWithEmptyValues() =
        runBlocking {
            val roomUser =
                object : RoomUser {
                    override val username = ""
                    override val roomId = ""
                    override val joinedAt: LocalDateTime = LocalDateTime.now()
                    override val role: Role = Role.USER_GUEST
                    override val clientType: ClientType = ClientType.CONTROLLER
                    override val deviceId: String = "device1"
                }
            val repository = TestRoomUserRepository(roomUser)
            val result = repository.currentUser()
            assertEquals("", result.username)
            assertEquals("", result.roomId)
        }
}

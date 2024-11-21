package io.patterueldev.session.participants

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservedsong.ReservedSongsRepository
import io.patterueldev.role.Role
import io.patterueldev.room.RoomRepository
import io.patterueldev.session.UserParticipant
import java.time.LocalDateTime
import java.time.ZoneOffset

internal class GetParticipantsFromRoomUseCase(
    private val roomRepository: RoomRepository,
    private val reservedSongRepository: ReservedSongsRepository,
) : ServiceUseCase<String, List<UserParticipant>> {
    override suspend fun execute(parameters: String): List<UserParticipant> {
        val room = roomRepository.findRoomById(parameters) ?: return emptyList()
        val usersInRoom =
            roomRepository.getUsersInRoom(room.id).let { users ->
                println("Users: $users")
                println("Before: ${users.size}")
                val filtered =
                    users.filter { user ->
                        user.role != Role.USER_HOST &&
                            user.joinedAt.isAfter(LocalDateTime.now().minusHours(3))
                    }
                println("After: ${filtered.size}")
                filtered
            }
        println("Users: ${usersInRoom.size}")
        val userIds = usersInRoom.map { it.username }
        val reservationsForUsersInRoom = reservedSongRepository.loadReservedSongsForUsersInRoom(userIds, room.id)

        return usersInRoom.map { user ->
            val reservationsForUser =
                reservationsForUsersInRoom.filter {
                    it.reservingUser == user.username && it.completed
                }
            object : UserParticipant(reservationsForUser.size) {
                override val name: String = user.username
                override val joinedAt = user.joinedAt.toEpochSecond(ZoneOffset.UTC)
            }
        }
    }
}

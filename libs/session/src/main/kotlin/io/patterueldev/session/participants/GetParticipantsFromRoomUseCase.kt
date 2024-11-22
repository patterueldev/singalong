package io.patterueldev.session.participants

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservedsong.ReservedSongsRepository
import io.patterueldev.role.Role
import io.patterueldev.room.RoomRepository
import io.patterueldev.roomuser.RoomUser
import io.patterueldev.session.UserParticipant
import java.time.LocalDateTime
import java.time.ZoneOffset
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope

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

        return usersInRoom.mapAsync { user ->
            val finished = reservedSongRepository.getCountForFinishedSongsByUserInRoom(user.username, user.roomId)
            val upcoming = reservedSongRepository.getCountForUpcomingSongsByUserInRoom(user.username, user.roomId)
            object : UserParticipant(finished, upcoming) {
                override val name: String = user.username
                override val joinedAt = user.joinedAt.toEpochSecond(ZoneOffset.UTC)
            }
        }
    }
}

suspend fun <A, B> Iterable<A>.mapAsync(transform: suspend (A) -> B): List<B> = coroutineScope {
    map { async { transform(it) } }.awaitAll()
}
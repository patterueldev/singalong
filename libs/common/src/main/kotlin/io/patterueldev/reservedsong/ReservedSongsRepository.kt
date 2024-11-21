package io.patterueldev.reservedsong

import io.patterueldev.roomuser.RoomUser
import java.time.LocalDateTime

interface ReservedSongsRepository {
    suspend fun reserveSong(
        roomUser: RoomUser,
        songId: String,
    ): ReservedSong

    suspend fun loadUnplayedReservedSongs(roomId: String): List<ReservedSong>

    suspend fun loadUnfinishedReservedSongs(roomId: String): List<ReservedSong>

    suspend fun markFinishedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
    )

    suspend fun markStartedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
    )

    suspend fun loadReservedSongsForUserInRoom(
        userId: String,
        roomId: String,
    ): List<ReservedSong>

    suspend fun loadReservedSongsForUsersInRoom(
        userIds: List<String>,
        roomId: String,
    ): List<ReservedSong>
}

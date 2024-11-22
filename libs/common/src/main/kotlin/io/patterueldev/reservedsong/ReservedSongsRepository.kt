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
        completed: Boolean,
    )

    suspend fun markStartedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
    )

    suspend fun getCountForFinishedSongsByUserInRoom(
        userId: String,
        roomId: String,
    ): Int

    suspend fun getCountForUpcomingSongsByUserInRoom(
        userId: String,
        roomId: String,
    ): Int
}

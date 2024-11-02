package io.patterueldev.reservation.reservedsong

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
}

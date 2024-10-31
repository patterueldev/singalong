package io.patterueldev.reservation.reservedsong

import io.patterueldev.roomuser.RoomUser
import java.time.LocalDateTime
import java.util.Date

interface ReservedSongsRepository {
    suspend fun reserveSong(
        roomUser: RoomUser,
        songId: String,
    )

    suspend fun loadReservedSongs(roomId: String): List<ReservedSong>

    suspend fun markFinishedPlaying(reservedSongId: String, at: LocalDateTime)
    suspend fun markStartedPlaying(reservedSongId: String, at: LocalDateTime)
}

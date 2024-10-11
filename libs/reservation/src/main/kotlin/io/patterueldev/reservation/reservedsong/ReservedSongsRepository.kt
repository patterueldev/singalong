package io.patterueldev.reservation.reservedsong

import io.patterueldev.roomuser.RoomUser

interface ReservedSongsRepository {
    suspend fun reserveSong(roomUser: RoomUser, songId: String)
    suspend fun loadReservedSongs(roomId: String): List<ReservedSong>
}
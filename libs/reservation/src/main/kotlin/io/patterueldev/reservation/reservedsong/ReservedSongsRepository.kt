package io.patterueldev.reservation.reservedsong

interface ReservedSongsRepository {
    suspend fun reserveSong(roomId: String, songId: String)
    fun loadReservedSongs(roomId: String): List<ReservedSong>
}
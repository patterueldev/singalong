package io.patterueldev.reservation.currentsong

interface CurrentSongRepository {
    suspend fun loadCurrentSong(roomId: String): CurrentSong?
}
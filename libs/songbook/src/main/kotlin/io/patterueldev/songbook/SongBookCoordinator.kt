package io.patterueldev.songbook

interface SongBookCoordinator {
    fun onReserveUpdate(roomId: String)

    fun onCurrentSongUpdate(roomId: String)
}

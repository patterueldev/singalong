package io.patterueldev.songidentifier

interface SongIdentifierCoordinator {
    fun onReserveUpdate(roomId: String)

    fun onCurrentSongUpdate(roomId: String)
}

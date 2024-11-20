package io.patterueldev.singalong

import io.patterueldev.admin.AdminCoordinator
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.singalong.realtime.OnEventListener
import io.patterueldev.songbook.SongBookCoordinator
import io.patterueldev.songidentifier.SongIdentifierCoordinator
import org.springframework.stereotype.Component

@Component
class ServerCoordinator : ReservationCoordinator, SongIdentifierCoordinator, AdminCoordinator, SongBookCoordinator {
    var onReserveUpdateListener: ((String) -> Unit)? = null
    var onCurrentSongUpdateListener: ((String) -> Unit)? = null
    var onAssignedPlayerToRoomListener: ((String, String) -> Unit)? = null
    var onRoomUpdateListener: OnEventListener? = null

    override fun onReserveUpdate(roomId: String) {
        onReserveUpdateListener?.invoke(roomId)
    }

    override fun onCurrentSongUpdate(roomId: String) {
        onCurrentSongUpdateListener?.invoke(roomId)
    }

    override fun onAssignedPlayerToRoom(
        playerId: String,
        roomId: String,
    ) {
        onAssignedPlayerToRoomListener?.invoke(playerId, roomId)
    }
}

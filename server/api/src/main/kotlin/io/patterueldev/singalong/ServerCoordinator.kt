package io.patterueldev.singalong

import io.patterueldev.admin.AdminCoordinator
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.singalong.realtime.OnEventListener
import io.patterueldev.songidentifier.SongIdentifierCoordinator
import org.springframework.stereotype.Component

@Component
class ServerCoordinator : ReservationCoordinator, SongIdentifierCoordinator, AdminCoordinator {
    private var onReserveUpdateListener: OnEventListener? = null
    private var onCurrentSongUpdateListener: OnEventListener? = null
    private var onAssignedPlayerToRoomListener: ((String, String) -> Unit)? = null

    override fun onReserveUpdate() {
        onReserveUpdateListener?.invoke()
    }

    override fun onCurrentSongUpdate() {
        onCurrentSongUpdateListener?.invoke()
    }

    override fun onAssignedPlayerToRoom(
        playerId: String,
        roomId: String,
    ) {
        onAssignedPlayerToRoomListener?.invoke(playerId, roomId)
    }

    fun setOnReserveUpdateListener(listener: OnEventListener) {
        onReserveUpdateListener = listener
    }

    fun setOnCurrentSongUpdateListener(listener: OnEventListener) {
        onCurrentSongUpdateListener = listener
    }

    fun setOnAssignedPlayerToRoomListener(listener: (String, String) -> Unit) {
        onAssignedPlayerToRoomListener = listener
    }
}

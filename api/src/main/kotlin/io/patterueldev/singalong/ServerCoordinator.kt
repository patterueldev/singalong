package io.patterueldev.singalong

import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.singalong.realtime.OnEventListener
import org.springframework.stereotype.Component

@Component
class ServerCoordinator : ReservationCoordinator {
    private var onReserveUpdateListener: OnEventListener? = null
    private var onCurrentSongUpdateListener: OnEventListener? = null

    override fun onReserveUpdate() {
        onReserveUpdateListener?.invoke()
    }

    override fun onCurrentSongUpdate() {
        onCurrentSongUpdateListener?.invoke()
    }

    fun setOnReserveUpdateListener(listener: OnEventListener) {
        onReserveUpdateListener = listener
    }

    fun setOnCurrentSongUpdateListener(listener: OnEventListener) {
        onCurrentSongUpdateListener = listener
    }
}

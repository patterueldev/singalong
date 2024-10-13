package io.patterueldev.singalong

import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.singalong.realtime.OnReserveSuccessListener
import org.springframework.stereotype.Component

@Component
class ServerCoordinator : ReservationCoordinator {
    private var onReserveSuccessListener: OnReserveSuccessListener? = null

    override fun onReserveSuccess() {
        onReserveSuccessListener?.invoke()
    }

    fun setOnReserveSuccessListener(listener: OnReserveSuccessListener) {
        onReserveSuccessListener = listener
    }
}

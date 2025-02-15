package io.patterueldev.reservation.cancel

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.reservedsong.ReservedSongsRepository

internal class CancelReservationUseCase(
    private val reservedSongsRepository: ReservedSongsRepository,
    private val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<CancelReservationParameters, Unit> {
    override suspend fun execute(parameters: CancelReservationParameters) {
        try {
            reservedSongsRepository.cancelReservation(
                roomId = parameters.roomId,
                reservedSongId = parameters.reservedSongId,
            )
            reservationCoordinator?.onReserveUpdate(roomId = parameters.roomId)
        } catch (e: Exception) {
            throw Exception(e.message ?: "An error occurred while canceling the reservation.")
        }
    }
}
package io.patterueldev.reservation.moveorder

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.reservedsong.ReservedSongsRepository

internal class MoveReservedSongOrderUseCase(
    private val reservedSongsRepository: ReservedSongsRepository,
    private val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<MoveReservedSongOrderParameters, Unit> {
    override suspend fun execute(parameters: MoveReservedSongOrderParameters) {
        try {
            reservedSongsRepository.moveReservedSongOrder(
                roomId = parameters.roomId,
                reservedSongId = parameters.reservedSongId,
                newOrder = parameters.newOrder,
            )
            reservationCoordinator?.onReserveUpdate(roomId = parameters.roomId)
        } catch (e: Exception) {
            throw Exception(e.message ?: "An error occurred while moving the reservation.")
        }
    }
}
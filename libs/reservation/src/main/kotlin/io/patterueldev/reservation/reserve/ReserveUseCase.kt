package io.patterueldev.reservation.reserve

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository

internal class ReserveUseCase(
    val reservedSongsRepository: ReservedSongsRepository,
    val roomUserRepository: RoomUserRepository,
    val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<ReserveParameters, ReserveResponse> {
    override suspend fun execute(parameters: ReserveParameters): ReserveResponse {
        return try {
            val user = roomUserRepository.currentUser()
            reservedSongsRepository.reserveSong(user, parameters.songId)
            reservationCoordinator?.onReserveSuccess()
            return GenericResponse.success(Unit, message = "Song reserved successfully.")
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading the reservation list.")
        }
    }
}

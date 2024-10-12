package io.patterueldev.reservation.list

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.NoParametersUseCase
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository

internal class LoadReservationListUseCase(
    private val reservedSongsRepository: ReservedSongsRepository,
) : ServiceUseCase<LoadReservationListParameters, LoadReservationListResponse> {
    override suspend fun execute(parameters: LoadReservationListParameters): LoadReservationListResponse {
        return try {
            val reservedSongs = reservedSongsRepository.loadReservedSongs(parameters.roomId)
            return GenericResponse.success(reservedSongs)
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading the reservation list.")
        }
    }
}

data class LoadReservationListParameters(
    val roomId: String
)
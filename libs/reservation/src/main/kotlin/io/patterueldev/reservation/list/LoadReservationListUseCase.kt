package io.patterueldev.reservation.list

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.NoParametersUseCase
import io.patterueldev.reservation.reservedsong.ReservedSong
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository

// TODO: I don't feel like I'm ever gonna use this use case
// TODO: because this will be done using websockets
// TODO: though, could potentially be used for the admin panel
internal class LoadReservationListUseCase(
    private val reservedSongsRepository: ReservedSongsRepository,
    private val roomUserRepository: RoomUserRepository,
) : NoParametersUseCase<LoadReservationListResponse> {
    override suspend fun execute(): LoadReservationListResponse {
        return try {
            val user = roomUserRepository.currentUser()
            val roomId = user.roomId
            val reservedSongs = reservedSongsRepository.loadReservedSongs(roomId)
            return GenericResponse.success(reservedSongs)
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading the reservation list.")
        }
    }
}

class LoadReservationListParameters

typealias LoadReservationListResponse = GenericResponse<List<ReservedSong>>
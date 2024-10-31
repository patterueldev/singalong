package io.patterueldev.reservation.next

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.NoParametersUseCase
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.reservation.currentsong.CurrentSongRepository
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository
import java.time.LocalDateTime

internal class NextSongUseCase(
    val reservedSongsRepository: ReservedSongsRepository,
    val currentSongRepository: CurrentSongRepository,
    val roomUserRepository: RoomUserRepository,
    val reservationCoordinator: ReservationCoordinator?,
) : NoParametersUseCase<NextSongResponse> {
    override suspend fun execute(): NextSongResponse {
        return try {
            val currentUser = roomUserRepository.currentUser()
            // TODO: Only either the room owner, the admin, or the reserving user can do this.
            val currentSong = currentSongRepository.loadCurrentSong(roomId = currentUser.roomId)
                ?: return GenericResponse.failure("No song is currently playing.")
            reservedSongsRepository.markFinishedPlaying(reservedSongId = currentSong.id, at = LocalDateTime.now())
            val reservedSongs = reservedSongsRepository.loadReservedSongs(roomId = currentUser.roomId)
            val nextSong = reservedSongs.firstOrNull()
            if (nextSong == null) {
                return GenericResponse.success(Unit, message = "No song reserved.")
            }
            reservedSongsRepository.markStartedPlaying(reservedSongId = nextSong.id, at = LocalDateTime.now())
            reservationCoordinator?.onReserveUpdate()
            reservationCoordinator?.onCurrentSongUpdate()
            return GenericResponse.success(Unit, message = "Song reserved successfully.")
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading the reservation list.")
        }
    }
}

typealias NextSongResponse = GenericResponse<Unit>
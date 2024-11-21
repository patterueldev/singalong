package io.patterueldev.reservation.next

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.reservation.currentsong.CurrentSongRepository
import io.patterueldev.reservedsong.ReservedSongsRepository
import io.patterueldev.reservedsong.ReservedSong
import io.patterueldev.roomuser.RoomUser
import io.patterueldev.roomuser.RoomUserRepository
import java.time.LocalDateTime

internal class NextSongUseCase(
    val reservedSongsRepository: ReservedSongsRepository,
    val currentSongRepository: CurrentSongRepository,
    val roomUserRepository: RoomUserRepository,
    val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<RoomUser?, NextSongResponse> {
    override suspend fun execute(parameters: RoomUser?): NextSongResponse {
        return try {
            // TODO: Only either the room owner, the admin, or the reserving user can do this.
            val currentUser = parameters ?: roomUserRepository.currentUser()
            val currentSong =
                currentSongRepository.loadCurrentSong(roomId = currentUser.roomId)
                    ?: return GenericResponse.failure("No song is currently playing.")
            reservedSongsRepository.markFinishedPlaying(reservedSongId = currentSong.id, at = LocalDateTime.now())
            val reservedSongs = reservedSongsRepository.loadUnplayedReservedSongs(roomId = currentUser.roomId)
            val nextSong = reservedSongs.firstOrNull()
            if (nextSong != null) {
                reservedSongsRepository.markStartedPlaying(reservedSongId = nextSong.id, at = LocalDateTime.now())
            }
            reservationCoordinator?.onReserveUpdate(roomId = currentUser.roomId)
            reservationCoordinator?.onCurrentSongUpdate(roomId = currentUser.roomId)
            return GenericResponse.success(nextSong, message = "Song has been skipped.")
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading the reservation list.")
        }
    }
}

typealias NextSongResponse = GenericResponse<ReservedSong?>

internal class SkipSongUseCase(
    val reservedSongsRepository: ReservedSongsRepository,
    val currentSongRepository: CurrentSongRepository,
    val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<SkipSongParameters, Unit> {
    override suspend fun execute(parameters: SkipSongParameters) {
        try {
            val currentSong =
                currentSongRepository.loadCurrentSong(roomId = parameters.roomId)
                    ?: throw Exception("No song is currently playing.")
            reservedSongsRepository.markFinishedPlaying(reservedSongId = currentSong.id, at = LocalDateTime.now())
            val reservedSongs = reservedSongsRepository.loadUnplayedReservedSongs(roomId = parameters.roomId)
            val nextSong = reservedSongs.firstOrNull()
            if (nextSong != null) {
                reservedSongsRepository.markStartedPlaying(reservedSongId = nextSong.id, at = LocalDateTime.now())
            }
            reservationCoordinator?.onReserveUpdate(roomId = parameters.roomId)
            reservationCoordinator?.onCurrentSongUpdate(roomId = parameters.roomId)
        } catch (e: Exception) {
            throw Exception(e.message ?: "An error occurred while loading the reservation list.")
        }
    }
}

data class SkipSongParameters(
    val roomId: String,
)

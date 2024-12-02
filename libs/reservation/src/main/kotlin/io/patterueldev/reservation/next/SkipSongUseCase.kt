package io.patterueldev.reservation.next

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.reservation.ReservationCoordinator
import io.patterueldev.reservation.currentsong.CurrentSongRepository
import io.patterueldev.reservedsong.ReservedSongsRepository
import java.time.LocalDateTime

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
            reservedSongsRepository.markFinishedPlaying(
                reservedSongId = currentSong.id,
                at = LocalDateTime.now(),
                completed = parameters.completed,
            )
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
    val completed: Boolean,
)

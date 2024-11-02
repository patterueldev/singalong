package io.patterueldev.reservation.currentsong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase

internal class LoadCurrentSongUseCase(
    private val currentSongRepository: CurrentSongRepository,
) : ServiceUseCase<LoadCurrentSongParameters, LoadCurrentSongResponse> {
    override suspend fun execute(parameters: LoadCurrentSongParameters): LoadCurrentSongResponse {
        try {
            println("Loading current song for room ${parameters.roomId}")
            val result = currentSongRepository.loadCurrentSong(parameters.roomId)
            return GenericResponse.success(result)
        } catch (e: Exception) {
            return GenericResponse.failure(e.message ?: "An error occurred while loading the current song.")
        }
    }
}

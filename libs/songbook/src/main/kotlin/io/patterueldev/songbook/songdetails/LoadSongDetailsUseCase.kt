package io.patterueldev.songbook.songdetails

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songbook.song.SongRepository

internal class LoadSongDetailsUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<LoadSongDetailsParameters, SongDetailsResponse> {
    override suspend fun execute(parameters: LoadSongDetailsParameters): SongDetailsResponse {
        try {
            val songDetails = songRepository.loadSongDetails(parameters.songId, parameters.roomId) ?: throw Exception("Song not found")
            return GenericResponse.success(songDetails)
        } catch (e: Exception) {
            return GenericResponse.failure(e.message ?: "An error occurred")
        }
    }
}

package io.patterueldev.songidentifier.identifysong

import io.patterueldev.shared.GenericResponse
import io.patterueldev.shared.ServiceUseCase
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.IdentifySongResponse

internal class IdentifySongUseCase(
    private val identifiedSongRepository: IdentifiedSongRepository
) : ServiceUseCase<IdentifySongParameters, IdentifySongResponse> {
    override suspend fun execute(parameters: IdentifySongParameters): IdentifySongResponse {
        try {
            val identifiedSong = identifiedSongRepository.identifySong(parameters.url)
                ?: return GenericResponse.failure(
                    message = "Song not found",
                    status = 404
                )
            val enhancedSong = identifiedSongRepository.enhanceSong(identifiedSong)
            return GenericResponse.success(enhancedSong)
        }
        catch (e: Exception) {
            return GenericResponse.failure(
                message = e.message ?: "An error occurred",
                status = 500
            )
        }
    }
}


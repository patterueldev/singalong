package io.patterueldev.songidentifier.identifysong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.identifysong.IdentifySongParameters
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.IdentifySongResponse

internal class IdentifySongUseCase(
    private val identifiedSongRepository: IdentifiedSongRepository,
) : ServiceUseCase<IdentifySongParameters, IdentifySongResponse> {
    override suspend fun execute(parameters: IdentifySongParameters): IdentifySongResponse {
        try {
            // TODO: VERY IMPORTANT; add logic to check if the song is already in the database
            val identifiedSong =
                identifiedSongRepository.identifySong(parameters.url)
                    ?: return GenericResponse.failure(
                        message = "Song not found",
                        status = 404,
                    )

            val existing = identifiedSongRepository.getExistingSong(identifiedSong)
            println("Attempting to check if song already exists")
            if (existing != null) {
                println("Song already exists")
                return GenericResponse.success(existing)
            }

            println("Song does not exist")

            val enhancedSong = identifiedSongRepository.enhanceSong(identifiedSong)
            return GenericResponse.success(enhancedSong)
        } catch (e: Exception) {
            return GenericResponse.failure(
                message = e.message ?: "An error occurred",
                status = 500,
            )
        }
    }
}

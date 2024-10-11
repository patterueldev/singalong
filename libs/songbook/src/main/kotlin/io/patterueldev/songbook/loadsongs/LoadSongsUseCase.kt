package io.patterueldev.songbook.loadsongs

import io.patterueldev.shared.GenericResponse
import io.patterueldev.shared.ServiceUseCase
import io.patterueldev.songbook.song.SongRepository

internal class LoadSongsUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<LoadSongsParameters, LoadSongsResponse> {
    override suspend fun execute(parameters: LoadSongsParameters): LoadSongsResponse {
        return try {
            parameters.validate()
            val songs = songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage())
            // TODO: in the future, we can add more logic here to handle the pagination
            // and return recommendations based on the keyword
            // or other business logic
            GenericResponse.success(songs)
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading songs.")
        }
    }
}

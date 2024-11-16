package io.patterueldev.songbook.loadsongs

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songbook.song.SongRepository

internal class LoadSongsUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<LoadSongsParameters, LoadSongsResponse> {
    override suspend fun execute(parameters: LoadSongsParameters): LoadSongsResponse {
        return try {
            parameters.validate()

            println("Parameters: $parameters")

            // if parameters, say, keyword is null, we will return recommendations
            if (parameters.recommendation()) {
                // move recommended to a separate use case because of the room ID
                // recommendations
                val reservedSongs = songRepository.loadReservedSongs(parameters.roomId!!)
                // TODO: Logic to return recommendations; for now just gonna filter out by ID
                val reservedSongIds = reservedSongs.map { it.id }
                val songs = songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage(), reservedSongIds)
                // if songs are not empty, return the songs; otherwise, continue to the next block
                if (songs.items.isNotEmpty()) {
                    return GenericResponse.success(songs)
                }
            }
            val songs = songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage())
            // TODO: in the future, we can add more logic here to handle the pagination
            // and return recommendations based on the keyword
            // or other business logic
            // TODO: TODO: !Important!
            // I feel like this is the most crucial part of the application
            GenericResponse.success(songs)
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading songs.")
        }
    }
}

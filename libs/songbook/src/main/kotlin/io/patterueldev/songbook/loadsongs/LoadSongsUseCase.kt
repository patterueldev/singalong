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

            val reservedSongs: List<SongbookItem> =
                parameters.roomId.let {
                    if (it == null) {
                        emptyList()
                    } else {
                        songRepository.loadReservedSongs(it)
                    }
                }

            var paginatedResult: PaginatedSongs? = null

            // if parameters, say, keyword is null, we will return recommendations
            if (parameters.recommendation()) {
                // move recommended to a separate use case because of the room ID
                // recommendations
                val reservedSongIds = reservedSongs.map { it.id }
                val songs = songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage(), reservedSongIds)
                // if songs are not empty, return the songs; otherwise, continue to the next block
                if (songs.items.isNotEmpty() || parameters.nextPage() != null) {
                    println("Returning recommended songs")
                    paginatedResult = songs
                }
            }

            paginatedResult = paginatedResult ?: songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage())

            paginatedResult.items.forEach { song ->
                val reservedSong = reservedSongs.find { it.id == song.id }
                if (reservedSong != null) {
                    song.alreadyPlayedInRoom = true
                }
            }
            if (parameters.keyword.isNullOrBlank()) {
                println("Returning shuffled songs")
                return GenericResponse.success(paginatedResult.shuffled())
            } else {
                println("Keyword: ${parameters.keyword}")
                println("Returning songs")
                return GenericResponse.success(paginatedResult)
            }
        } catch (e: Exception) {
            GenericResponse.failure(e.message ?: "An error occurred while loading songs.")
        }
    }
}

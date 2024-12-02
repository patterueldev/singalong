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

            val reservedSongsInRoom: List<SongbookItem> =
                parameters.roomId.let {
                    if (it == null) {
                        emptyList()
                    } else {
                        songRepository.loadReservedSongsInRoom(it)
                    }
                }

            println("Found ${reservedSongsInRoom.size} reserved songs in room")

            var paginatedResult: PaginatedSongs? = null

            // if parameters, say, keyword is null, we will return recommendations
            if (parameters.recommendation()) {
                // move recommended to a separate use case because of the room ID
                // recommendations
                val reservedSongIds = reservedSongsInRoom.map { it.id }
                val songs = songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage(), reservedSongIds)
                // if songs are not empty, return the songs; otherwise, continue to the next block
                if (songs.items.isNotEmpty() || parameters.nextPage() != null) {
                    println("Returning recommended songs")
                    paginatedResult = songs
                }
            }

            paginatedResult = paginatedResult ?: songRepository.loadSongs(parameters.limit, parameters.keyword, parameters.nextPage())

            paginatedResult.items.forEach { song ->
                val reservedSong = reservedSongsInRoom.find { it.id == song.id }
                if (reservedSong != null) {
                    println("Song ${song.id} was reserved and already played in room")
                    song.alreadyPlayedInRoom = true
                } else {
                    println("Song ${song.id} was not reserved and not yet played in room")
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

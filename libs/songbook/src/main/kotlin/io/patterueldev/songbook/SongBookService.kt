package io.patterueldev.songbook

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songbook.loadsongs.LoadSongsUseCase
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.LoadSongDetailsParameters
import io.patterueldev.songbook.songdetails.LoadSongDetailsUseCase
import io.patterueldev.songbook.songdetails.SongDetailsResponse

class SongBookService(
    private val songRepository: SongRepository,
) {
    private val loadSongsUseCase: LoadSongsUseCase by lazy {
        LoadSongsUseCase(songRepository)
    }

    private val loadSongDetailsUseCase: LoadSongDetailsUseCase by lazy {
        LoadSongDetailsUseCase(songRepository)
    }

    private val updateSongUseCase: UpdateSongUseCase by lazy {
        UpdateSongUseCase(songRepository)
    }

    suspend fun loadSongs(parameters: LoadSongsParameters) = loadSongsUseCase(parameters)

    suspend fun loadSong(parameters: LoadSongDetailsParameters) = loadSongDetailsUseCase(parameters)

    suspend fun updateSong(parameters: UpdateSongParameters) = updateSongUseCase(parameters)
}

data class UpdateSongParameters(
    val songId: String,
    val title: String,
    val artist: String,
    val language: String,
    val isOffVocal: Boolean,
    val videoHasLyrics: Boolean,
    val songLyrics: String,
    val metadata: Map<String, String>,
    val genres: List<String>,
    val tags: List<String>,
)

internal class UpdateSongUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<UpdateSongParameters, SongDetailsResponse> {
    override suspend fun execute(parameters: UpdateSongParameters): SongDetailsResponse {
        val result = songRepository.updateSongDetails(parameters)
        return GenericResponse.success(result)
    }
}

package io.patterueldev.songbook

import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songbook.loadsongs.LoadSongsUseCase
import io.patterueldev.songbook.song.SongRepository

class SongBookService(
    private val songRepository: SongRepository,
) {
    private val loadSongsUseCase: LoadSongsUseCase by lazy {
        LoadSongsUseCase(songRepository)
    }

    suspend fun loadSongs(parameters: LoadSongsParameters) = loadSongsUseCase(parameters)
}

package io.patterueldev.songbook

import io.patterueldev.songbook.common.SongRepository
import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songbook.loadsongs.LoadSongsUseCase
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service

@Service
class SongBookService {
    @Autowired private lateinit var songRepository: SongRepository
    private val loadSongsUseCase: LoadSongsUseCase by lazy {
        LoadSongsUseCase(songRepository)
    }

    suspend fun loadSongs(parameters: LoadSongsParameters) = loadSongsUseCase(parameters)
}
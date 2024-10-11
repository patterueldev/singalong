package io.patterueldev.songidentifier

import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.identifysong.IdentifySongParameters
import io.patterueldev.songidentifier.identifysong.IdentifySongUseCase
import io.patterueldev.songidentifier.savesong.SaveSongParameters
import io.patterueldev.songidentifier.savesong.SaveSongUseCase
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service

@Service
class SongIdentifierService {
    @Autowired private lateinit var identifiedSongRepository: IdentifiedSongRepository
    private val identifySongUseCase: IdentifySongUseCase by lazy {
        IdentifySongUseCase(identifiedSongRepository)
    }

    private val saveSongUseCase: SaveSongUseCase by lazy {
        SaveSongUseCase(identifiedSongRepository)
    }

    suspend fun identifySong(parameters: IdentifySongParameters) = identifySongUseCase(parameters)

    suspend fun saveSong(parameters: SaveSongParameters) = saveSongUseCase(parameters)
}

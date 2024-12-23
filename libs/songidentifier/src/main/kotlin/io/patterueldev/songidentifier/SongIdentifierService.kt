package io.patterueldev.songidentifier

import io.patterueldev.identifysong.IdentifySongParameters
import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.identifysong.IdentifySongUseCase
import io.patterueldev.songidentifier.savesong.SaveSongParameters
import io.patterueldev.songidentifier.savesong.SaveSongUseCase
import io.patterueldev.songidentifier.searchsong.SearchSongParameters
import io.patterueldev.songidentifier.searchsong.SearchSongUseCase

class SongIdentifierService(
    private val identifiedSongRepository: IdentifiedSongRepository,
    private val roomUserRepository: RoomUserRepository,
    val songIdentifierCoordinator: SongIdentifierCoordinator? = null,
) {
    private val identifySongUseCase: IdentifySongUseCase by lazy {
        IdentifySongUseCase(identifiedSongRepository)
    }

    private val saveSongUseCase: SaveSongUseCase by lazy {
        SaveSongUseCase(identifiedSongRepository, roomUserRepository, songIdentifierCoordinator)
    }

    private val searchSongUseCase: SearchSongUseCase by lazy {
        SearchSongUseCase(identifiedSongRepository)
    }

    suspend fun identifySong(parameters: IdentifySongParameters) = identifySongUseCase(parameters)

    suspend fun saveSong(parameters: SaveSongParameters) = saveSongUseCase(parameters)

    suspend fun searchSong(parameters: SearchSongParameters) = searchSongUseCase(parameters)
}

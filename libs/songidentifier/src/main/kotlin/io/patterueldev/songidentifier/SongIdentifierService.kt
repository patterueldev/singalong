package io.patterueldev.songidentifier

import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.identifysong.IdentifySongParameters
import io.patterueldev.songidentifier.identifysong.IdentifySongUseCase
import io.patterueldev.songidentifier.savesong.SaveSongParameters
import io.patterueldev.songidentifier.savesong.SaveSongUseCase

class SongIdentifierService(
    private val identifiedSongRepository: IdentifiedSongRepository,
    private val roomUserRepository: RoomUserRepository,
) {
    private val identifySongUseCase: IdentifySongUseCase by lazy {
        IdentifySongUseCase(identifiedSongRepository)
    }

    private val saveSongUseCase: SaveSongUseCase by lazy {
        SaveSongUseCase(identifiedSongRepository, roomUserRepository)
    }

    suspend fun identifySong(parameters: IdentifySongParameters) = identifySongUseCase(parameters)

    suspend fun saveSong(parameters: SaveSongParameters) = saveSongUseCase(parameters)
}

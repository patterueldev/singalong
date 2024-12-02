package io.patterueldev.songbook

import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songbook.deletesong.DeleteSongUseCase
import io.patterueldev.songbook.enhancesong.EnhanceSongParameters
import io.patterueldev.songbook.enhancesong.EnhanceSongUseCase
import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songbook.loadsongs.LoadSongsUseCase
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.LoadSongDetailsParameters
import io.patterueldev.songbook.songdetails.LoadSongDetailsUseCase
import io.patterueldev.songbook.updatesong.UpdateSongParameters
import io.patterueldev.songbook.updatesong.UpdateSongUseCase

class SongBookService(
    private val songRepository: SongRepository,
    private val roomUserRepository: RoomUserRepository,
    val songBookCoordinator: SongBookCoordinator? = null,
) {
    private val loadSongsUseCase: LoadSongsUseCase by lazy {
        LoadSongsUseCase(songRepository)
    }

    private val loadSongDetailsUseCase: LoadSongDetailsUseCase by lazy {
        LoadSongDetailsUseCase(songRepository)
    }

    private val updateSongUseCase: UpdateSongUseCase by lazy {
        UpdateSongUseCase(songRepository, roomUserRepository, songBookCoordinator)
    }

    private val deleteSongUseCase: DeleteSongUseCase by lazy {
        DeleteSongUseCase(songRepository)
    }

    private val enhanceSongUseCase: EnhanceSongUseCase by lazy {
        EnhanceSongUseCase(songRepository)
    }

    suspend fun loadSongs(parameters: LoadSongsParameters) = loadSongsUseCase(parameters)

    suspend fun loadSong(parameters: LoadSongDetailsParameters) = loadSongDetailsUseCase(parameters)

    suspend fun updateSong(parameters: UpdateSongParameters) = updateSongUseCase(parameters)

    suspend fun deleteSong(songId: String) = deleteSongUseCase(songId)

    suspend fun enhanceSong(parameters: EnhanceSongParameters) = enhanceSongUseCase(parameters)
}

package io.patterueldev.songidentifier.savesong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songidentifier.SongIdentifierCoordinator
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.SaveSongResponse
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

internal open class SaveSongUseCase(
    private val identifiedSongRepository: IdentifiedSongRepository,
    private val roomUserRepository: RoomUserRepository,
    private val songIdentifierCoordinator: SongIdentifierCoordinator?,
) : ServiceUseCase<SaveSongParameters, SaveSongResponse> {
    private val mutex = Mutex()

    @OptIn(DelicateCoroutinesApi::class)
    override suspend fun execute(parameters: SaveSongParameters): SaveSongResponse {
        val user = roomUserRepository.currentUser()

        val identifiedSong = parameters.song
        val videoId = identifiedSong.id
        val videoTitle = identifiedSong.songTitle
        val fileTitle = videoTitle.replace(Regex("[/\\\\?%*:|\"<>]"), "-").replace(Regex("\\s+"), "-").lowercase()
        val filename = "$fileTitle[$videoId]"

        // execute on the background thread
        GlobalScope.launch {
            mutex.withLock {
                val downloadedVideo = identifiedSongRepository.downloadSongVideo(identifiedSong.source, filename)
                val downloadedThumbnail = identifiedSongRepository.downloadSongThumbnail(identifiedSong.imageUrl, filename)
                val newSong =
                    identifiedSongRepository.saveSong(
                        parameters.song,
                        user.username,
                        user.roomId,
                        downloadedVideo,
                        downloadedThumbnail,
                    )
                if (parameters.thenReserve) {
                    val reservedSong = identifiedSongRepository.reserveSong(user, newSong.id)
                    songIdentifierCoordinator?.onReserveUpdate(user.roomId)
                    if (reservedSong.currentPlaying) {
                        songIdentifierCoordinator?.onCurrentSongUpdate(user.roomId)
                    }
                }
            }
        }
        return GenericResponse.success(true)
    }
}

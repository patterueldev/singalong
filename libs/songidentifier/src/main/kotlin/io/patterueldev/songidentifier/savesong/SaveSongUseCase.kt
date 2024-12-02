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
        val filename = toFileTitle(videoTitle, videoId)

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

    private fun toFileTitle(
        videoTitle: String,
        videoId: String,
    ): String {
        // 1. extract only alphanumeric and dash characters
        // 2. replace multiple dashes with a single dash
        // 3. remove leading and trailing dashes
        // 4. lowercase the string
        val filter1 = videoTitle.replace(Regex("[^a-zA-Z0-9-]"), "")
        val filter2 = filter1.replace(Regex("-+"), "-")
        val filter3 = filter2.removePrefix("-").removeSuffix("-")
        return "$filter3[$videoId]"
    }
}

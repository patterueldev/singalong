package io.patterueldev.songidentifier.savesong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.SaveSongResponse

internal open class SaveSongUseCase(
    private val identifiedSongRepository: IdentifiedSongRepository,
    private val roomUserRepository: RoomUserRepository,
) : ServiceUseCase<SaveSongParameters, SaveSongResponse> {
    override suspend fun execute(parameters: SaveSongParameters): SaveSongResponse {
        val user = roomUserRepository.currentUser()

        val identifiedSong = parameters.song
        val videoId = identifiedSong.id
        val videoTitle = identifiedSong.songTitle
        val fileTitle = videoTitle.replace(Regex("[/\\\\?%*:|\"<>]"), "-").replace(Regex("\\s+"), "-").lowercase()
        val filename = "$fileTitle[$videoId]"

        // TODO: Check if the song is already saved
        var newSong = identifiedSongRepository.saveSong(parameters.song, user.username, user.roomId)
        newSong = identifiedSongRepository.downloadThumbnail(newSong, identifiedSong.imageUrl, filename)

        val savedSongId = newSong.id

        // I want to encapsulate this area ---- to under some thread
        newSong = identifiedSongRepository.downloadSong(newSong, identifiedSong.source, filename)
        if (parameters.thenReserve) {
            identifiedSongRepository.reserveSong(savedSongId, user.roomId)
        }
        // when didFinish is true, mark the song as downloaded
        // and then reserve the song, if true
        // this should occur on the background

        // TODO: Do the above in the future; for now, let's do these asynchronously
        // I just need to see if the downloading works

        return GenericResponse.success(newSong)
    }
}

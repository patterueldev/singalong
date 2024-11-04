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

        var newSong = identifiedSongRepository.saveSong(parameters.song, user.username, user.roomId)
        newSong = identifiedSongRepository.downloadThumbnail(newSong, identifiedSong.imageUrl, filename)
        newSong = identifiedSongRepository.downloadSong(newSong, identifiedSong.source, filename)
        return GenericResponse.success(newSong)
    }
}

package io.patterueldev.songidentifier.savesong

import io.patterueldev.shared.GenericResponse
import io.patterueldev.shared.ServiceUseCase
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.SaveSongResponse

internal open class SaveSongUseCase(
    private val identifiedSongRepository: IdentifiedSongRepository,
) : ServiceUseCase<SaveSongParameters, SaveSongResponse> {
    override suspend fun execute(parameters: SaveSongParameters): SaveSongResponse {
        val identifiedSong = parameters.song
        val videoId = identifiedSong.id
        val videoTitle = identifiedSong.songTitle
        val savedSongId = identifiedSongRepository.saveSong(parameters.song, parameters.userId, parameters.sessionId)

        val fileTitle = videoTitle.replace(Regex("[/\\\\?%*:|\"<>]"), "-").replace(Regex("\\s+"), "-").lowercase()
        val filename = "$fileTitle[$videoId].mp4"

        // I want to encapsulate this area ---- to under some thread
        val didFinish = identifiedSongRepository.downloadSong(identifiedSong.source, filename)
        identifiedSongRepository.updateSong(savedSongId, filename) // marks the song as downloaded
        if (parameters.thenReserve) {
            identifiedSongRepository.reserveSong(savedSongId, parameters.sessionId)
        }
        // when didFinish is true, mark the song as downloaded
        // and then reserve the song, if true
        // this should occur on the background

        // TODO: Do the above in the future; for now, let's do these asynchronously
        // I just need to see if the downloading works

        return GenericResponse.success(identifiedSong)
    }
}

package io.patterueldev.songbook.enhancesong

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.SongDetailsResponse

internal class EnhanceSongUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<EnhanceSongParameters, SongDetailsResponse> {
    override suspend fun execute(parameters: EnhanceSongParameters): SongDetailsResponse {
        return try {
            val result = songRepository.enhanceSong(parameters.songId)
            SongDetailsResponse.success(result)
        } catch (e: Exception) {
            SongDetailsResponse.failure(e.message ?: "An error occurred while enhancing the song.")
        }
    }
}

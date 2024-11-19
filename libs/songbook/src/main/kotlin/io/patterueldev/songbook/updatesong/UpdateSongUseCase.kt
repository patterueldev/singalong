package io.patterueldev.songbook.updatesong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.SongDetailsResponse

internal class UpdateSongUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<UpdateSongParameters, SongDetailsResponse> {
    override suspend fun execute(parameters: UpdateSongParameters): SongDetailsResponse {
        val result = songRepository.updateSongDetails(parameters)
        return GenericResponse.success(result)
    }
}

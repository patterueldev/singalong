package io.patterueldev.songbook.updatesong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songbook.SongBookCoordinator
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.SongDetailsResponse

internal class UpdateSongUseCase(
    private val songRepository: SongRepository,
    private val roomUserRepository: RoomUserRepository,
    private val songBookCoordinator: SongBookCoordinator?,
) : ServiceUseCase<UpdateSongParameters, SongDetailsResponse> {
    override suspend fun execute(parameters: UpdateSongParameters): SongDetailsResponse {
        val user = roomUserRepository.currentUser()
        val result = songRepository.updateSongDetails(parameters, user)
        // coordinator update reservations
        songBookCoordinator?.onReserveUpdate(user.roomId)
        return GenericResponse.success(result)
    }
}

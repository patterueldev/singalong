package io.patterueldev.reservation

import io.patterueldev.reservation.currentsong.CurrentSongRepository
import io.patterueldev.reservation.currentsong.LoadCurrentSongParameters
import io.patterueldev.reservation.currentsong.LoadCurrentSongUseCase
import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.reservation.list.LoadReservationListUseCase
import io.patterueldev.reservation.next.SkipSongParameters
import io.patterueldev.reservation.next.SkipSongUseCase
import io.patterueldev.reservation.reserve.ReserveParameters
import io.patterueldev.reservation.reserve.ReserveUseCase
import io.patterueldev.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository

class ReservationService(
    val reservedSongsRepository: ReservedSongsRepository,
    val currentSongRepository: CurrentSongRepository,
    val roomUserRepository: RoomUserRepository,
    val reservationCoordinator: ReservationCoordinator? = null,
) {
    private val reserveUseCase: ReserveUseCase by lazy {
        ReserveUseCase(reservedSongsRepository, roomUserRepository, reservationCoordinator)
    }

    private val loadReservationListUseCase: LoadReservationListUseCase by lazy {
        LoadReservationListUseCase(reservedSongsRepository)
    }

    private val loadCurrentSongUseCase: LoadCurrentSongUseCase by lazy {
        LoadCurrentSongUseCase(currentSongRepository)
    }

    private val skipSongUseCase: SkipSongUseCase by lazy {
        SkipSongUseCase(reservedSongsRepository, currentSongRepository, reservationCoordinator)
    }

    suspend fun reserveSong(parameters: ReserveParameters) = reserveUseCase(parameters)

    suspend fun skipSong(parameters: SkipSongParameters) = skipSongUseCase(parameters)

    suspend fun loadReservationList(parameters: LoadReservationListParameters) = loadReservationListUseCase(parameters)

    suspend fun loadCurrentSong(parameters: LoadCurrentSongParameters) = loadCurrentSongUseCase(parameters)
}

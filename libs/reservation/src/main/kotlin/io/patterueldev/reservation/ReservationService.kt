package io.patterueldev.reservation

import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.reservation.list.LoadReservationListUseCase
import io.patterueldev.reservation.reserve.ReserveParameters
import io.patterueldev.reservation.reserve.ReserveUseCase
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository

class ReservationService(
    val reservedSongsRepository: ReservedSongsRepository,
    val roomUserRepository: RoomUserRepository,
) {
    private val reserveUseCase: ReserveUseCase by lazy {
        ReserveUseCase(reservedSongsRepository, roomUserRepository)
    }

    private val loadReservationListUseCase: LoadReservationListUseCase by lazy {
        LoadReservationListUseCase(reservedSongsRepository)
    }

    suspend fun reserveSong(parameters: ReserveParameters) = reserveUseCase.execute(parameters)

    suspend fun loadReservationList(parameters: LoadReservationListParameters) = loadReservationListUseCase.execute(parameters)
}

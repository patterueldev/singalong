package io.patterueldev.reservation

import io.patterueldev.reservation.list.LoadReservationListUseCase
import io.patterueldev.reservation.reserve.ReserveParameters
import io.patterueldev.reservation.reserve.ReserveUseCase
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository

class ReservationService(
    val reservedSongsRepository: ReservedSongsRepository,
    val roomUserRepository: RoomUserRepository
) {
    private val reserveUseCase: ReserveUseCase by lazy {
        ReserveUseCase(reservedSongsRepository, roomUserRepository)
    }

    private val loadReservationListUseCase: LoadReservationListUseCase by lazy {
        LoadReservationListUseCase(reservedSongsRepository, roomUserRepository)
    }

    suspend fun reserveSong(parameters: ReserveParameters) = reserveUseCase.execute(parameters)

    suspend fun loadReservationList() = loadReservationListUseCase.execute()
}
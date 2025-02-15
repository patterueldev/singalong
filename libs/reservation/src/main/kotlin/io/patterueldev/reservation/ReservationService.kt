package io.patterueldev.reservation

import io.patterueldev.common.ServiceUseCase
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

    private val cancelReservationUseCase: CancelReservationUseCase by lazy {
        CancelReservationUseCase(reservedSongsRepository, reservationCoordinator)
    }

    private val moveReservedSongOrderUseCase: MoveReservedSongOrderUseCase by lazy {
        MoveReservedSongOrderUseCase(reservedSongsRepository, reservationCoordinator)
    }

    suspend fun reserveSong(parameters: ReserveParameters) = reserveUseCase(parameters)

    suspend fun skipSong(parameters: SkipSongParameters) = skipSongUseCase(parameters)

    suspend fun loadReservationList(parameters: LoadReservationListParameters) = loadReservationListUseCase(parameters)

    suspend fun loadCurrentSong(parameters: LoadCurrentSongParameters) = loadCurrentSongUseCase(parameters)

    suspend fun cancelReservation(parameters: CancelReservationParameters) = cancelReservationUseCase(parameters)

    suspend fun moveReservedSongOrder(parameters: MoveReservedSongOrderParameters) = moveReservedSongOrderUseCase(parameters)
}

internal class CancelReservationUseCase(
    private val reservedSongsRepository: ReservedSongsRepository,
    private val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<CancelReservationParameters, Unit> {
    override suspend fun execute(parameters: CancelReservationParameters) {
        try {
            reservedSongsRepository.cancelReservation(
                roomId = parameters.roomId,
                reservedSongId = parameters.reservedSongId,
            )
            reservationCoordinator?.onReserveUpdate(roomId = parameters.roomId)
        } catch (e: Exception) {
            throw Exception(e.message ?: "An error occurred while canceling the reservation.")
        }
    }
}

data class CancelReservationParameters(
    val roomId: String,
    val reservedSongId: String,
)

internal class MoveReservedSongOrderUseCase(
    private val reservedSongsRepository: ReservedSongsRepository,
    private val reservationCoordinator: ReservationCoordinator?,
) : ServiceUseCase<MoveReservedSongOrderParameters, Unit> {
    override suspend fun execute(parameters: MoveReservedSongOrderParameters) {
        try {
            reservedSongsRepository.moveReservedSongOrder(
                roomId = parameters.roomId,
                reservedSongId = parameters.reservedSongId,
                newOrder = parameters.newOrder,
            )
            reservationCoordinator?.onReserveUpdate(roomId = parameters.roomId)
        } catch (e: Exception) {
            throw Exception(e.message ?: "An error occurred while moving the reservation.")
        }
    }
}

data class MoveReservedSongOrderParameters(
    val roomId: String,
    val reservedSongId: String,
    val newOrder: Int,
)

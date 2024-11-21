package io.patterueldev.singalong

import com.corundumstudio.socketio.SocketIOServer
import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.currentsong.LoadCurrentSongParameters
import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.reservation.next.SkipSongParameters
import io.patterueldev.session.SessionService
import jakarta.annotation.PreDestroy
import kotlinx.coroutines.runBlocking
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component

@Component
class SingalongService {
    @Autowired
    private lateinit var sessionService: SessionService

    @Autowired
    private lateinit var reservationService: ReservationService

    @Autowired
    private lateinit var socketIOServer: SocketIOServer

    suspend fun start() {
        // Start socket.io server
        socketIOServer.start()
    }

    @PreDestroy
    fun stopServer() {
        // could potentially mark the room as inactive
        println("Stopping socketIO server...")
        socketIOServer.stop()
    }

    fun getActiveRooms() =
        runBlocking {
            sessionService.getActiveRooms()
        }

    fun getAssignedRoom(userId: String) =
        runBlocking {
            sessionService.getAssignedRoomForPlayer(userId)
        }

    fun getReservedSongs(roomId: String) =
        runBlocking {
            reservationService.loadReservationList(
                parameters = LoadReservationListParameters(roomId),
            ).data ?: listOf()
        }

    fun getCurrentSong(roomId: String) =
        runBlocking {
            reservationService.loadCurrentSong(
                parameters = LoadCurrentSongParameters(roomId),
            ).data
        }

    fun skipSong(parameters: SkipSongParameters) =
        runBlocking {
            reservationService.skipSong(
                parameters = parameters,
            )
        }

    fun getParticipantsInRoom(roomId: String) =
        runBlocking {
            sessionService.getParticipantsFromRoom(roomId)
        }
}

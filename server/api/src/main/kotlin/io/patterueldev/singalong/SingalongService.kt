package io.patterueldev.singalong

import com.corundumstudio.socketio.SocketIOServer
import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.currentsong.LoadCurrentSongParameters
import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.reservation.next.SkipSongParameters
import io.patterueldev.room.Room
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

    // TODO: The active room should not be automatically set now; it will be set by admin
    var activeRoom: Room? = null
//    var activeRooms = mutableListOf<Room>()

    suspend fun start() {
        // get list of active rooms
//        activeRooms = sessionService.getActiveRooms().toMutableList()
//        println("Fetched ${activeRooms.size} room(s)")
        // Start session service
//        println("Starting session service...")
//        activeRoom =
//            runBlocking {
//                sessionService.findOrCreateRoom()
//            }.data
//        println("Active room: $activeRoom")

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

    fun skipSong(roomId: String) =
        runBlocking {
            reservationService.skipSong(
                parameters = SkipSongParameters(roomId),
            )
        }
}

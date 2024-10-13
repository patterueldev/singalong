package io.patterueldev.singalong

import com.corundumstudio.socketio.SocketIOServer
import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.session.SessionService
import io.patterueldev.session.room.Room
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
    private lateinit var server: SocketIOServer

    lateinit var activeRoom: Room

    fun start() {
        // Start session service
        activeRoom =
            runBlocking {
                sessionService.findOrCreateRoom()
            }.data!!
        println("Active room: $activeRoom")

        // Start socket.io server
        server.start()
    }

    @PreDestroy
    fun stopServer() {
        // could potentially mark the room as inactive
        println("Stopping socketIO server...")
        server.stop()
    }

    fun getReservedSongs() =
        runBlocking {
            reservationService.loadReservationList(
                parameters = LoadReservationListParameters(activeRoom.id),
            ).data ?: listOf()
        }
}

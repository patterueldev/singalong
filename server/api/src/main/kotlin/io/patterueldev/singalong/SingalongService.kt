package io.patterueldev.singalong

import com.corundumstudio.socketio.SocketIOServer
import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.currentsong.LoadCurrentSongParameters
import io.patterueldev.reservation.list.LoadReservationListParameters
import io.patterueldev.room.Room
import io.patterueldev.roomuser.RoomUser
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
    private lateinit var server: SocketIOServer

    var activeRoom: Room? = null

    fun start() {
        // Start session service
        println("Starting session service...")
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
            val id = activeRoom?.id ?: return@runBlocking listOf()
            reservationService.loadReservationList(
                parameters = LoadReservationListParameters(id),
            ).data ?: listOf()
        }

    fun getCurrentSong() =
        runBlocking {
            val id = activeRoom?.id ?: return@runBlocking null
            reservationService.loadCurrentSong(
                parameters = LoadCurrentSongParameters(id),
            ).data
        }

    suspend fun skipSong(
        username: String,
        roomId: String,
    ) = reservationService.nextSong(
        object : RoomUser {
            override val username: String
                get() = username
            override val roomId: String
                get() = roomId
        },
    )
}

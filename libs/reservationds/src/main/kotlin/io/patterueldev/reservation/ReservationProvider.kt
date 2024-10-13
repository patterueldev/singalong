package io.patterueldev.reservation

import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class ReservationProvider {
    @Bean
    open fun reservationService(
        @Autowired reservedSongsRepository: ReservedSongsRepository,
        @Autowired roomUserRepository: RoomUserRepository,
        @Autowired(required = false) reservationCoordinator: ReservationCoordinator? = null,
    ) = ReservationService(reservedSongsRepository, roomUserRepository, reservationCoordinator)
}

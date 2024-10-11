package io.patterueldev.reservation

import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUserRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class ReservationConfiguration {
    @Bean
    open fun reservationService(
        @Autowired reservedSongsRepository: ReservedSongsRepository,
        @Autowired roomUserRepository: RoomUserRepository
    ) = ReservationService(reservedSongsRepository, roomUserRepository)
}
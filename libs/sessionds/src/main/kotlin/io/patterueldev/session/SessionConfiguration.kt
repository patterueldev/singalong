package io.patterueldev.session

import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.reservedsong.ReservedSongsRepository
import io.patterueldev.room.RoomRepository
import io.patterueldev.roomuser.RoomUserRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder

@Configuration
open class SessionConfiguration {
    @Bean
    open fun passwordEncoder(): PasswordEncoder {
        return BCryptPasswordEncoder()
    }

    @Bean
    open fun sessionService(
        @Autowired authUserRepository: AuthUserRepository,
        @Autowired roomUserRepository: RoomUserRepository,
        @Autowired roomRepository: RoomRepository,
        @Autowired authRepository: AuthRepository,
        @Autowired reservedSongRepository: ReservedSongsRepository,
    ) = SessionService(
        authUserRepository = authUserRepository,
        roomUserRepository = roomUserRepository,
        roomRepository = roomRepository,
        authRepository = authRepository,
        reservedSongRepository = reservedSongRepository,
    )
}

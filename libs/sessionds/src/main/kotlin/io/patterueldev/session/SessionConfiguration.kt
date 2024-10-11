package io.patterueldev.session

import SessionService
import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.session.room.RoomRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder

@Configuration
open class SessionConfiguration {
    @Bean
    open fun sessionService(
        @Autowired authUserRepository: AuthUserRepository,
        @Autowired roomRepository: RoomRepository,
        @Autowired authRepository: AuthRepository,
    ) = SessionService(
        authUserRepository = authUserRepository,
        roomRepository = roomRepository,
        authRepository = authRepository,
    )
}

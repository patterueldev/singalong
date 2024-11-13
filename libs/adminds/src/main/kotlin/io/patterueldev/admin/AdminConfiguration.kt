package io.patterueldev.admin

import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.room.RoomRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class AdminConfiguration {
    @Bean
    open fun adminService(
        @Autowired roomRepository: RoomRepository,
        @Autowired authRepository: AuthRepository,
        @Autowired authUserRepository: AuthUserRepository,
    ) = AdminService(roomRepository, authRepository, authUserRepository)
}

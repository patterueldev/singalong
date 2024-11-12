package io.patterueldev.admin

import io.patterueldev.room.RoomRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class AdminConfiguration {
    @Bean
    open fun adminService(
        @Autowired roomRepository: RoomRepository,
    ) = AdminService(roomRepository)
}

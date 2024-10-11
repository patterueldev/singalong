package io.patterueldev.songidentifier

import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.roomuser.RoomUserRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class SongIdentifierConfiguration {
    @Bean
    open fun songIdentifierService(
        @Autowired identifiedSongRepository: IdentifiedSongRepository,
        @Autowired roomUserRepository: RoomUserRepository,
    ) = SongIdentifierService(identifiedSongRepository, roomUserRepository)
}

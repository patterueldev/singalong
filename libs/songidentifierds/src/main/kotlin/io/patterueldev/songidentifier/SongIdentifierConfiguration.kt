package io.patterueldev.songidentifier

import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class SongIdentifierConfiguration {
    @Bean
    open fun songIdentifierService(
        @Autowired identifiedSongRepository: IdentifiedSongRepository,
    ) = SongIdentifierService(identifiedSongRepository)
}

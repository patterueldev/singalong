package io.patterueldev.songbook

import io.patterueldev.songbook.song.SongRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class SongBookConfiguration {
    @Bean
    open fun songBookService(
        @Autowired songRepository: SongRepository,
    ) = SongBookService(songRepository)
}

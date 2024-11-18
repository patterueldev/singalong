package io.patterueldev.songidentifier

import io.minio.MinioClient
import io.patterueldev.roomuser.RoomUserRepository
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.codec.ClientCodecConfigurer
import org.springframework.web.reactive.function.client.ExchangeStrategies
import org.springframework.web.reactive.function.client.WebClient

@Configuration
open class SongIdentifierConfiguration {
    @Bean
    open fun jsServiceWebClient(
        @Value("\${baseurl.js-service}") jsServiceUrl: String,
    ): WebClient {
        val sizeInMB = 200
        val sizeInBytes = sizeInMB * 1024 * 1024
        val strategies =
            ExchangeStrategies.builder()
                .codecs { codecs: ClientCodecConfigurer -> codecs.defaultCodecs().maxInMemorySize(sizeInBytes) }
                .build()

        return WebClient.builder()
            .baseUrl(jsServiceUrl)
            .exchangeStrategies(strategies)
            .build()
    }

    @Bean
    open fun songIdentifierService(
        @Autowired identifiedSongRepository: IdentifiedSongRepository,
        @Autowired roomUserRepository: RoomUserRepository,
        @Autowired(required = false) songIdentifierCoordinator: SongIdentifierCoordinator? = null,
    ) = SongIdentifierService(identifiedSongRepository, roomUserRepository, songIdentifierCoordinator)

    @Bean
    open fun minioClient(
        @Value("\${minio.endpoint}") endpoint: String,
        @Value("\${minio.accessKey}") accessKey: String,
        @Value("\${minio.secretKey}") secretKey: String,
    ): MinioClient {
        return MinioClient.builder()
            .endpoint(endpoint)
            .credentials(accessKey, secretKey)
            .build()
    }
}

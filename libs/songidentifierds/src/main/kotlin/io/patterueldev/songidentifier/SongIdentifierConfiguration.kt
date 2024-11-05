package io.patterueldev.songidentifier

import com.aallam.openai.api.model.ModelId
import com.aallam.openai.client.OpenAI
import com.aallam.openai.client.OpenAIConfig
import com.aallam.openai.client.OpenAIHost
import com.aallam.openai.client.RetryStrategy
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
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
    open fun songDownloaderClient(
        @Value("\${baseurl.songdownloader}") songDownloaderUrl: String,
    ): WebClient {
        val sizeInMB = 200
        val sizeInBytes = sizeInMB * 1024 * 1024
        val strategies =
            ExchangeStrategies.builder()
                .codecs { codecs: ClientCodecConfigurer -> codecs.defaultCodecs().maxInMemorySize(sizeInBytes) }
                .build()

        return WebClient.builder()
            .baseUrl(songDownloaderUrl)
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
    open fun openAIClient(
        @Value("\${openai.local}") local: Boolean,
        @Value("\${openai.token}") token: String,
        @Value("\${openai.host}") host: String,
    ): OpenAI {
        if (!local) {
            return OpenAI(
                OpenAIConfig(token),
            )
        }
        return OpenAI(
            OpenAIConfig(
                token = token,
                host = OpenAIHost(host),
                retry = RetryStrategy(maxRetries = 1),
                engine = HttpClient(CIO).engine,
            ),
        )
    }

    @Bean
    open fun openAIModel(
        @Value("\${openai.model}") model: String,
    ): ModelId = ModelId(model)

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

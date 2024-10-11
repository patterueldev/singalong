package io.patterueldev.singalong

import com.aallam.openai.api.model.ModelId
import com.aallam.openai.client.OpenAI
import com.aallam.openai.client.OpenAIConfig
import com.aallam.openai.client.OpenAIHost
import com.aallam.openai.client.RetryStrategy
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.client.WebClient

@Configuration
class AppConfiguration {
    @Bean
    fun songDownloaderClient(
        @Value("\${baseurl.songdownloader}") songDownloaderUrl: String,
    ): WebClient =
        WebClient.builder()
            .baseUrl(songDownloaderUrl)
            .build()

    @Bean
    fun openAIClient(
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
    fun openAIModel(
        @Value("\${openai.model}") model: String,
    ): ModelId = ModelId(model)
}

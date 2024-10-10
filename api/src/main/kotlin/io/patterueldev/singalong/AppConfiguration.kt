package io.patterueldev.singalong

import SessionService
import com.aallam.openai.api.model.ModelId
import com.aallam.openai.client.OpenAI
import com.aallam.openai.client.OpenAIConfig
import com.aallam.openai.client.OpenAIHost
import com.aallam.openai.client.RetryStrategy
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.session.auth.AuthUserRepository
import io.patterueldev.session.jwt.JwtTokenFilter
import io.patterueldev.session.room.RoomRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer


@Configuration
@EnableWebSecurity
class AppConfiguration {

    @Autowired
    private val jwtTokenFilter: JwtTokenFilter? = null

    @Value("\${cors.allowedOrigins}")
    private lateinit var allowedOrigins: String

    @Bean
    fun corsConfigurer(): WebMvcConfigurer {
        return object : WebMvcConfigurer {
            override fun addCorsMappings(registry: CorsRegistry) {
                val origins = allowedOrigins.split(",").toTypedArray()
                println("Allowed origins: ${origins.joinToString(" | ")}")
                registry.addMapping("/**")
                    .allowedOrigins(*origins)
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH")
                    .allowedHeaders("*")
                    .allowCredentials(true)
            }
        }
    }

    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http.authorizeHttpRequests {
            it.anyRequest().permitAll()
        }
//        http.addFilterBefore(jwtTokenFilter, UsernamePasswordAuthenticationFilter::class.java)
        return http.build()
    }

    @Bean
    fun songDownloaderClient(
        @Value("\${baseurl.songdownloader}") songDownloaderUrl: String
    ): WebClient
        = WebClient.builder()
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
                OpenAIConfig(token)
            )
        }
        return OpenAI(
            OpenAIConfig(
                token = token,
                host = OpenAIHost(host),
                retry = RetryStrategy(maxRetries = 1),
                engine = HttpClient(CIO).engine
            )
        )
    }

    @Bean
    fun openAIModel(
        @Value("\${openai.model}") model: String
    ): ModelId
        = ModelId(model)

    @Bean
    fun sessionService(
        @Autowired authUserRepository: AuthUserRepository,
        @Autowired roomRepository: RoomRepository,
        @Autowired authRepository: AuthRepository
    ): SessionService {
        return SessionService(
            authUserRepository = authUserRepository,
            roomRepository = roomRepository,
            authRepository = authRepository
        )
    }

    @Bean
    fun passwordEncoder(): PasswordEncoder {
        return BCryptPasswordEncoder()
    }
}
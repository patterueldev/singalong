package io.patterueldev.singalong.security

import io.patterueldev.session.jwt.JwtAuthenticationEntryPoint
import io.patterueldev.session.jwt.JwtAuthenticationProvider
import io.patterueldev.session.jwt.JwtSecurityContextRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
@EnableWebSecurity
class SecurityConfiguration {
    @Autowired
    private lateinit var jwtAuthenticationEntryPoint: JwtAuthenticationEntryPoint

    @Autowired
    private lateinit var jwtAuthenticationProvider: JwtAuthenticationProvider

    @Autowired
    private lateinit var jwtSecurityContextRepository: JwtSecurityContextRepository

    @Bean
    fun corsConfigurer(
        @Value("\${cors.allowedOrigins}") allowedOrigins: String,
    ): WebMvcConfigurer {
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
        val whitelisted =
            arrayOf(
                "/session/connect",
                "/swagger-ui/**",
                "/swagger-resources/**",
                "/v3/api-docs/**",
                "/swagger-resources",
            )
        return http.csrf { it.disable() }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .exceptionHandling { it.authenticationEntryPoint(jwtAuthenticationEntryPoint) }
            .authenticationProvider(jwtAuthenticationProvider)
            .securityContext { it.securityContextRepository(jwtSecurityContextRepository) }
            .authorizeHttpRequests {
                whitelisted.forEach { path -> it.requestMatchers(path).permitAll() }
                it.anyRequest().authenticated()
            }
            .build()
    }
}

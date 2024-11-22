package io.patterueldev.singalong.security

import io.patterueldev.jwt.JwtAuthenticationEntryPoint
import io.patterueldev.jwt.JwtAuthenticationProvider
import io.patterueldev.jwt.JwtSecurityContextRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource

@Configuration
@EnableWebSecurity
class SecurityConfiguration(
    @Value("\${cors.allowedHosts}") val allowedHosts: String,
    @Value("\${cors.allowedPorts}") val allowedPorts: String,
) {
    @Autowired
    private lateinit var jwtAuthenticationEntryPoint: JwtAuthenticationEntryPoint

    @Autowired
    private lateinit var jwtAuthenticationProvider: JwtAuthenticationProvider

    @Autowired
    private lateinit var jwtSecurityContextRepository: JwtSecurityContextRepository

    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        val whitelisted =
            arrayOf(
                "/session/connect",
                "/swagger-ui/**",
                "/swagger-resources/**",
                "/v3/api-docs/**",
                "/swagger-resources",
                "/songs/thumbnail/**",
                "/source-image/**",
            )
        return http.csrf { it.disable() }
            .cors { it.configurationSource(corsConfigurationSource()) }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .exceptionHandling { it.authenticationEntryPoint(jwtAuthenticationEntryPoint) }
            .authenticationProvider(jwtAuthenticationProvider)
            .securityContext { it.securityContextRepository(jwtSecurityContextRepository) }
            .authorizeHttpRequests {
                whitelisted.forEach { path -> it.requestMatchers(path).permitAll() }
                it.requestMatchers("/admin/**").hasRole("ADMIN")
                it.anyRequest().authenticated()
            }
            .build()
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val allowedOrigins: MutableList<String> = mutableListOf()
        allowedHosts.split(",").forEach { host ->
            // add the plain 80
            allowedOrigins.add("http://$host")
            allowedPorts.split(",").forEach { port ->
                allowedOrigins.add("http://$host:$port")
            }
        }
        println("Allowed origins: \n${allowedOrigins.joinToString("\n    ")}")
        val configuration = CorsConfiguration()
        configuration.allowedOrigins = allowedOrigins
        configuration.allowedMethods = listOf("GET", "POST", "PUT", "DELETE", "PATCH")
        configuration.allowedHeaders = listOf("*")
        configuration.allowCredentials = true
        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", configuration)
        return source
    }
}

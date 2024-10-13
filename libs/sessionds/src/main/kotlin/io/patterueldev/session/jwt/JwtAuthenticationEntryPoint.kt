package io.patterueldev.session.jwt

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import io.patterueldev.common.GenericResponse
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.core.AuthenticationException
import org.springframework.security.web.AuthenticationEntryPoint
import org.springframework.stereotype.Component

@Component
class JwtAuthenticationEntryPoint : AuthenticationEntryPoint {
    override fun commence(
        request: HttpServletRequest?,
        response: HttpServletResponse?,
        authException: AuthenticationException?,
    ) {
        if (response != null && !response.isCommitted) {
            response.contentType = "application/json"
            response.status = HttpServletResponse.SC_UNAUTHORIZED
            val json =
                GenericResponse.failure<Any>(
                    message = "Unauthorized",
                    status = HttpServletResponse.SC_UNAUTHORIZED,
                )
            jacksonObjectMapper().writer().writeValue(response.writer, json)
        }
    }
}

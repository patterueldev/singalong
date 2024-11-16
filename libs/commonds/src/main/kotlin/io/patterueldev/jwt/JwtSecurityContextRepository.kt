package io.patterueldev.jwt

import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.core.context.SecurityContext
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.context.HttpRequestResponseHolder
import org.springframework.security.web.context.SecurityContextRepository
import org.springframework.stereotype.Component

@Component
class JwtSecurityContextRepository(
    private val jwtUtil: JwtUtil,
) : SecurityContextRepository {
    override fun loadContext(requestResponseHolder: HttpRequestResponseHolder): SecurityContext {
        val securityContext = SecurityContextHolder.createEmptyContext()

        val request = requestResponseHolder.request
        val token = resolveToken(request)

        if (token != null && jwtUtil.isTokenValid(token)) {
            val userDetails = jwtUtil.getUserDetails(token)
            val authentication = JwtAuthenticationToken(userDetails, token, userDetails.authorities)
            securityContext.authentication = authentication
        }

        return securityContext
    }

    override fun saveContext(
        context: SecurityContext,
        request: HttpServletRequest,
        response: HttpServletResponse,
    ) {
        // Stateless, so no need to save anything here
    }

    override fun containsContext(request: HttpServletRequest): Boolean {
        return resolveToken(request) != null
    }

    private fun resolveToken(request: HttpServletRequest): String? {
        val bearerToken = request.getHeader("Authorization")
        return if (!bearerToken.isNullOrEmpty() && bearerToken.startsWith("Bearer ")) {
            bearerToken.substring(7)
        } else {
            null
        }
    }
}

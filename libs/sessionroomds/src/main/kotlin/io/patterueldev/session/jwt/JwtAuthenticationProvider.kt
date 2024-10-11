package io.patterueldev.session.jwt

import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.session.room.RoomUserDetails
import jakarta.servlet.http.HttpServletRequest
import org.springframework.security.authentication.AuthenticationProvider
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource
import org.springframework.stereotype.Component

@Component
class JwtAuthenticationProvider(
    private val jwtUtil: JwtUtil
) : AuthenticationProvider {

    override fun authenticate(authentication: Authentication): Authentication {
        val token = (authentication as JwtAuthenticationToken).getToken()

        if (!jwtUtil.isTokenValid(token)) {
            throw BadCredentialsException("Invalid token")
        }

        val userDetails = jwtUtil.getUserDetails(token)
        return JwtAuthenticationToken(userDetails.username, token, userDetails.authorities)
    }


    override fun supports(authentication: Class<*>): Boolean {
        return JwtAuthenticationToken::class.java.isAssignableFrom(authentication)
    }
}
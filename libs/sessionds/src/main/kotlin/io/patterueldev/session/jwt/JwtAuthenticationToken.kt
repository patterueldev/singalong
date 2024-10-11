package io.patterueldev.session.jwt

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.GrantedAuthority

class JwtAuthenticationToken(
    // Username or ID
    private val principal: String,
    // JWT token
    private val token: String,
    authorities: Collection<GrantedAuthority>,
) : UsernamePasswordAuthenticationToken(principal, null, authorities) {
    override fun getCredentials(): Any? {
        // No credentials required for JWT
        return null
    }

    override fun getPrincipal(): Any {
        return this.principal
    }

    fun getToken(): String {
        return this.token
    }
}

package io.patterueldev.session.jwt

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.GrantedAuthority

class JwtAuthenticationToken(
    private val principal: String,  // Username or ID
    private val token: String,      // JWT token
    private val authorities: Collection<GrantedAuthority>
) : UsernamePasswordAuthenticationToken(principal, null, authorities) {

    override fun getCredentials(): Any? {
        return null // No credentials required for JWT
    }

    override fun getPrincipal(): Any {
        return this.principal
    }

    fun getToken(): String {
        return this.token
    }
}
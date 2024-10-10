package io.patterueldev.session.jwt

import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.session.auth.AuthUser
import jakarta.servlet.FilterChain
import jakarta.servlet.ServletException
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter
import java.io.IOException

@Component
class JwtTokenFilter(val userDocumentRepository: UserDocumentRepository) : OncePerRequestFilter() {

    @Autowired
    private lateinit var jwtUtil: JwtUtil

    @Throws(ServletException::class, IOException::class)
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        println("JwtTokenFilter.doFilterInternal")
        if (!hasAuthorizationBearer(request)) {
            println("No Authorization Bearer")
            println("Request URI: ${request.requestURI}")
            filterChain.doFilter(request, response)
            return
        }

        val token = getAccessToken(request)

        if (!jwtUtil.isTokenValid(token)) {
            filterChain.doFilter(request, response)
            return
        }

        setAuthenticationContext(token, request)
        filterChain.doFilter(request, response)
    }

    private fun hasAuthorizationBearer(request: HttpServletRequest): Boolean {
        val header = request.getHeader("Authorization")
        return !header.isNullOrEmpty() && header.startsWith("Bearer")
    }

    private fun getAccessToken(request: HttpServletRequest): String {
        val header = request.getHeader("Authorization")
        return header.split(" ")[1].trim()
    }

    private fun setAuthenticationContext(token: String, request: HttpServletRequest) {
        val userDetails = getUserDetails(token)

        val authentication = UsernamePasswordAuthenticationToken(
            userDetails,
            null,
            userDetails.authorities
        )

        authentication.details = WebAuthenticationDetailsSource().buildDetails(request)

        SecurityContextHolder.getContext().authentication = authentication
    }

    private fun getUserDetails(token: String): UserDetails {
        val jwtSubject = jwtUtil.extractSubject(token)

        if (jwtSubject != null) {
            val user = userDocumentRepository.findByUsername(jwtSubject)
            if(user != null) {
                return object : UserDetails {
                    override fun getAuthorities(): Collection<GrantedAuthority> {
                        return listOf(SimpleGrantedAuthority("USER"))
                    }

                    override fun getPassword(): String {
                        return user.passcode ?: ""
                    }

                    override fun getUsername(): String {
                        return user.username
                    }
                }
            }
        }
        throw Exception("jwtSubject is null")
    }


}
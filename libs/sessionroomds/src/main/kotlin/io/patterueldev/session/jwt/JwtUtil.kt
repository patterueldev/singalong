package io.patterueldev.session.jwt

//import com.nimbusds.jose.JWSAlgorithm
//import com.nimbusds.jose.crypto.MACSigner
//import com.nimbusds.jose.crypto.MACVerifier
//import com.nimbusds.jwt.JWTClaimsSet
//import com.nimbusds.jwt.SignedJWT
import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import io.patterueldev.mongods.user.UserDocumentRepository
import io.patterueldev.session.room.RoomUserDetails
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.util.*
import javax.crypto.Cipher.SECRET_KEY
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.stereotype.Component


@Component
class JwtUtil(
    @Value("\${jwt.secret}") private val secret: String,
    private val userDocumentRepository: UserDocumentRepository
) {
    private val logger = LoggerFactory.getLogger(this.javaClass)
    private val key = Keys.hmacShaKeyFor(secret.toByteArray(StandardCharsets.UTF_8))

    fun generateToken(username: String, roomid: String): String {
        return Jwts.builder()
            .subject(username)
            .claim("roomId", roomid)
            .issuedAt(Date())
            .expiration(Date.from(Instant.now().plusSeconds(JWT_EXPIRATION_TIME)))
            .signWith(key)
            .compact()
    }

    fun extractSubject(token: String): String? {
        try {
            val claims = extractAllClaims(token)
            return claims.subject
        } catch (e: Exception) {
            e.printStackTrace()
            logger.error("- - - - [MALFORMED TOKEN] - - - -")
        }
        return null
    }

    fun extractRoomId(token: String): String? {
        try {
            val claims = extractAllClaims(token)
            return claims["roomId"] as String
        } catch (e: Exception) {
            e.printStackTrace()
            logger.error("- - - - [MALFORMED TOKEN] - - - -")
        }
        return null
    }

    private fun extractAllClaims(token: String): Claims {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).payload
    }


    fun isTokenValid(token: String): Boolean {
        val isValid = !isTokenExpired(token) && isSignatureValid(token)
        println("Is Valid: $isValid")
        return isValid
    }

    private fun isSignatureValid(token: String): Boolean {
        return try {
            val claims = extractAllClaims(token) // TODO: Find out how to verify signature
            return true
//            val signedJWT = SignedJWT.parse(token)
//            val verifier = MACVerifier(secret)
//            signedJWT.verify(verifier)
        } catch (e: Exception) {
            logger.error("- - - - [INVALID TOKEN SIGNATURE] - - - -")
            false
        }
    }

    private fun isTokenExpired(token: String): Boolean {
        return try {
            val claims = extractAllClaims(token)
            val expirationTime = claims.expiration.time
            val currentTime = Date().time
            expirationTime < currentTime
        } catch (e: Exception) {
            logger.error("-  - - - [EXPIRED TOKEN] - - - -")
            true
        }
    }

    fun getUserDetails(token: String): UserDetails {
        val jwtSubject = extractSubject(token)
        val jwtRoomId = extractRoomId(token)
        if (jwtSubject != null) {
            val user = userDocumentRepository.findByUsername(jwtSubject)
            if(user != null) {
                return RoomUserDetails(
                    user = user,
                    roomId = jwtRoomId ?: "",
                    rawAuthorities = listOf(SimpleGrantedAuthority("ROLE_USER"))
                )
            }
        }
        throw Exception("jwtSubject is null")
    }

    companion object {
        private const val ONE_HOUR: Long = (60 * 60)
        const val JWT_EXPIRATION_TIME = ONE_HOUR
    }
}
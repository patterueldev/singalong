package io.patterueldev.session.jwt

import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import io.patterueldev.authuser.RoomUserDetails
import io.patterueldev.client.ClientType
import io.patterueldev.mongods.room.RoomDocumentRepository
import io.patterueldev.mongods.user.UserDocumentRepository
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.stereotype.Component
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.util.Date

@Component
class JwtUtil(
    @Value("\${jwt.secret}") private val secret: String,
    private val userDocumentRepository: UserDocumentRepository,
    private val roomDocumentRepository: RoomDocumentRepository,
) {
    private val key = Keys.hmacShaKeyFor(secret.toByteArray(StandardCharsets.UTF_8))

    fun generateToken(
        username: String,
        roomid: String,
        clientType: ClientType,
    ): String {
        return Jwts.builder()
            .subject(username)
            .claim("roomId", roomid)
            .claim("clientType", clientType)
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
            println("- - - - [MALFORMED TOKEN] - - - -")
        }
        return null
    }

    fun extractRoomId(token: String): String? {
        try {
            val claims = extractAllClaims(token)
            return claims["roomId"] as String
        } catch (e: Exception) {
            e.printStackTrace()
            println("- - - - [MALFORMED TOKEN] - - - -")
        }
        return null
    }

    fun extractClientType(token: String): ClientType? {
        try {
            val claims = extractAllClaims(token)
            return ClientType.valueOf(claims["clientType"] as String)
        } catch (e: Exception) {
            e.printStackTrace()
            println("- - - - [MALFORMED TOKEN] - - - -")
        }
        return null
    }

    private fun extractAllClaims(token: String): Claims {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).payload
    }

    fun isTokenValid(token: String): Boolean {
        val isValid = !isTokenExpired(token)
        println("Is Valid: $isValid")
        return isValid
    }

    private fun isTokenExpired(token: String): Boolean {
        return try {
            val claims = extractAllClaims(token)
            val now = Date()
            val expirationTime = claims.expiration.time
            val currentTime = now.time
            println("Expiration Time: ${claims.expiration}")
            println("Current Time: $now")
            expirationTime < currentTime
        } catch (e: Exception) {
            println("-  - - - [EXPIRED TOKEN] - - - -")
            true
        }
    }

    fun getUserDetails(token: String): RoomUserDetails {
        val jwtSubject = extractSubject(token) ?: throw Exception("Subject not found")
        val jwtRoomId = extractRoomId(token) ?: throw Exception("Room ID not found")
        val clientType = extractClientType(token) ?: throw Exception("Client Type not found")

        val user = userDocumentRepository.findByUsername(jwtSubject) ?: throw Exception("User not found")
        val room = roomDocumentRepository.findRoomById(jwtRoomId) ?: throw Exception("Room not found")
        if (room.archivedAt != null) {
            throw Exception("Room is not active anymore")
        }
        val role = user.role
        return RoomUserDetails(
            user = user,
            roomId = jwtRoomId,
            role = role,
            clientType = clientType,
            rawAuthorities = listOf(SimpleGrantedAuthority("ROLE_$role")),
        )
    }

    companion object {
        private const val ONE_HOUR: Long = (60 * 60)
        const val JWT_EXPIRATION_TIME = ONE_HOUR
    }
}

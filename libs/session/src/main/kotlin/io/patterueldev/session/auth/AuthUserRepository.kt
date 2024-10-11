package io.patterueldev.session.auth

interface AuthUserRepository {
    fun findUserByUsername(username: String): AuthUser?
    fun createUser(username: String, passcode: String?): AuthUser
    fun authenticateUser(username: String, passcode: String): String? // probably should return a token
}


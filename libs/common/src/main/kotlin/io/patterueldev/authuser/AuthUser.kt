package io.patterueldev.authuser

interface AuthUser {
    val username: String
    val hashedPasscode: String?
}

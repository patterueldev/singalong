package io.patterueldev.session.authuser

interface AuthUser {
    val username: String
    val hashedPasscode: String?
}

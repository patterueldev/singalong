package io.patterueldev.session.auth

interface AuthUser {
    val username: String
    val hashedPasscode: String?
}

package io.patterueldev.session.authuser

import io.patterueldev.role.Role

interface AuthUser {
    val username: String
    val hashedPasscode: String?
    val role: Role
}

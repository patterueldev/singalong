package io.patterueldev.authuser

import io.patterueldev.role.Role

interface AuthUserRepository {
    fun createUser(
        username: String,
        passcode: String?,
        role: Role = Role.USER_GUEST,
    ): AuthUser

    fun currentUser(): AuthUser

    fun findUserByUsername(username: String): AuthUser?

    fun updateUser(
        username: String,
        passcode: String?,
        unset: Boolean,
    ): AuthUser
}

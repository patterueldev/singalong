package io.patterueldev.session.authuser

interface AuthUserRepository {
    fun findUserByUsername(username: String): AuthUser?

    fun createUser(
        username: String,
        passcode: String?,
    ): AuthUser

    fun updateUser(
        username: String,
        passcode: String?,
        unset: Boolean,
    ): AuthUser

    fun currentUser(): AuthUser
}

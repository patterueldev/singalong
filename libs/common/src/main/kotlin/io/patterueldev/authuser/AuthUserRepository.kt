package io.patterueldev.authuser

interface AuthUserRepository {
    fun createUser(
        username: String,
        passcode: String?,
    ): AuthUser
    fun currentUser(): AuthUser
    fun findUserByUsername(username: String): AuthUser?
    fun updateUser(
        username: String,
        passcode: String?,
        unset: Boolean,
    ): AuthUser
}

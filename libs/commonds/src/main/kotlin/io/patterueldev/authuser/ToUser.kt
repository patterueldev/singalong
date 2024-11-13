package io.patterueldev.authuser

import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.role.Role

fun UserDocument.toUser(): AuthUser {
    return object : AuthUser {
        override val username: String = this@toUser.username
        override val hashedPasscode: String? = this@toUser.passcode
        override val role: Role = this@toUser.role
    }
}

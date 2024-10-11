package io.patterueldev.user

import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.session.auth.AuthUser

fun UserDocument.toUser(): AuthUser {
    return object : AuthUser {
        override val username: String = this@toUser.username
        override val hashedPasscode: String? = this@toUser.passcode
    }
}

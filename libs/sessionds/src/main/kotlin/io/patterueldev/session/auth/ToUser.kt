package io.patterueldev.session.auth

import io.patterueldev.mongods.user.UserDocument

fun UserDocument.toUser(): AuthUser {
    return object : AuthUser {
        override val username: String = this@toUser.username
        override val hashedPasscode: String? = this@toUser.passcode
    }
}

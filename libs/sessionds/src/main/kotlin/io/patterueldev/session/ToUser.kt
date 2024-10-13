package io.patterueldev.session

import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.session.authuser.AuthUser

fun UserDocument.toUser(): AuthUser {
    return object : AuthUser {
        override val username: String = this@toUser.username
        override val hashedPasscode: String? = this@toUser.passcode
    }
}

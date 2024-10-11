package io.patterueldev.session.auth

import io.patterueldev.authuser.AuthUser
import io.patterueldev.session.room.Room

interface AuthRepository {
    fun matchPasscode(
        plainPasscode: String,
        hashedPasscode: String,
    ): Boolean

    fun addUserToRoom(authUser: AuthUser, room: Room): String // probably should return a token
}

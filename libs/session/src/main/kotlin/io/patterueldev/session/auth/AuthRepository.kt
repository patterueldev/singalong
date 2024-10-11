package io.patterueldev.session.auth

import io.patterueldev.session.room.Room

interface AuthRepository {
    fun matchPasscode(passcode: String, hashedPasscode: String): Boolean
    fun addUserToRoom(authUser: AuthUser, room: Room): String // probably should return a token
}
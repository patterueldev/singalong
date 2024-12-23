package io.patterueldev.room

interface Room {
    val id: String
    val name: String
    val passcode: String? // Remember: Passcode for User and Room are different
    val isArchived: Boolean

    fun isAdminRoom(): Boolean {
        return id == "admin"
    }

    // TODO: Might not need this in the future
    fun isIdleRoom(): Boolean {
        return id == "idle"
    }
}

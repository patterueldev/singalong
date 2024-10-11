package io.patterueldev.session.room

interface Room {
    val id: String
    val name: String
    val passcode: String? // Remember: Passcode for User and Room are different
}

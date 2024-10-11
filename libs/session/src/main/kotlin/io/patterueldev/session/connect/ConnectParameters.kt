package io.patterueldev.session.connect

data class ConnectParameters(
    val username: String,
    val userPasscode: String?,
    val roomId: String,
    val roomPasscode: String?
)
package io.patterueldev.session.connect

import io.patterueldev.client.ClientType

data class ConnectParameters(
    val username: String,
    val userPasscode: String?,
    val roomId: String,
    val roomPasscode: String?,
    val clientType: ClientType,
    val deviceId: String,
)

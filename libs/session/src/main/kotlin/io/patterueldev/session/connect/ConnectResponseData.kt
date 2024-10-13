package io.patterueldev.session.connect

data class ConnectResponseData(
    val requiresUserPasscode: Boolean? = null,
    val requiresRoomPasscode: Boolean? = null,
    val accessToken: String? = null,
)

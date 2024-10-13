package io.patterueldev.session.setuserpasscode

data class SetUserPasscodeParameters(
    val currentPasscode: String?,
    val newPasscode: String?,
    val unsetPasscode: Boolean = false,
)

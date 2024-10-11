package io.patterueldev.session.setuserpasscode

import io.patterueldev.session.authuser.AuthUser
import io.patterueldev.session.authuser.AuthUserRepository
import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase

internal class SetUserPasscodeUseCase(
    private val authRepository: AuthRepository,
    private val authUserRepository: AuthUserRepository,
) : ServiceUseCase<SetUserPasscodeParameters, SetUserPasscodeResponse> {
    override suspend fun execute(parameters: SetUserPasscodeParameters): SetUserPasscodeResponse {
        val user =
            authUserRepository.currentUser()
                ?: throw IllegalArgumentException("User not found")
        val currentlyHasPasscode = user.hashedPasscode != null
        if (currentlyHasPasscode) {
            val currentParameterPasscode = parameters.currentPasscode ?: throw IllegalArgumentException("Current passcode is required")
            val currentUserHashedPasscode =
                user.hashedPasscode
                    ?: throw IllegalArgumentException("User has no passcode")
            val matched =
                !authRepository.matchPasscode(
                    plainPasscode = currentParameterPasscode,
                    hashedPasscode = currentUserHashedPasscode,
                )
            if (!matched) {
                throw IllegalArgumentException("Invalid passcode")
            }
            // proceed to set new passcode
        }

        val updatedUser: AuthUser
        if (parameters.unsetPasscode) {
            updatedUser =
                authUserRepository.updateUser(
                    username = user.username,
                    passcode = null,
                    unset = true,
                )
        } else {
            updatedUser =
                authUserRepository.updateUser(
                    username = user.username,
                    passcode = parameters.newPasscode,
                    unset = false,
                )
        }
        println("User ${user.username} updated passcode")
        println("${user.hashedPasscode}")
        return GenericResponse.success(Unit)
    }
}

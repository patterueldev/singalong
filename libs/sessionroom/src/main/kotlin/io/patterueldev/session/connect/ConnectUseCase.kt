package io.patterueldev.session.connect

import io.patterueldev.session.room.RoomRepository
import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.session.common.ConnectResponse
import io.patterueldev.shared.GenericResponse
import io.patterueldev.shared.ServiceUseCase
import io.patterueldev.session.auth.AuthUserRepository

internal class ConnectUseCase(
    private val roomRepository: RoomRepository,
    private val authUserRepository: AuthUserRepository,
    private val authRepository: AuthRepository,
) : ServiceUseCase<ConnectParameters, ConnectResponse> {
    override suspend fun execute(parameters: ConnectParameters): ConnectResponse {
        println("ConnectUseCase: $parameters")
        // step1: find the room
        val room = roomRepository.findRoomById(parameters.roomId) ?: return GenericResponse.failure("Room not found")
        // step2: fetch the user
        var user = authUserRepository.findUserByUsername(parameters.username)
        // step2.1: if the user does not exist, create it
        if (user == null) {
            user = authUserRepository.createUser(parameters.username, parameters.userPasscode)
        }
        // step3: check if the user requires a passcode
        val requiresUserPasscode = user.hashedPasscode != null

        // step4: check if the room also requires a passcode
        val requiresRoomPasscode = room.passcode != null

        // Check parameters if passcode(s) were not provided
        if (requiresUserPasscode || requiresRoomPasscode) {
            val isUserPasscodeRequiredAndProvided = requiresUserPasscode && parameters.userPasscode != null
            val isRoomPasscodeRequiredAndProvided = requiresRoomPasscode && parameters.roomPasscode != null

            // Check if any required passcode was not provided
            if (!isUserPasscodeRequiredAndProvided || !isRoomPasscodeRequiredAndProvided) {
                // Compose appropriate error message based on which passcodes are missing
                val message = when {
                    !isUserPasscodeRequiredAndProvided && !isRoomPasscodeRequiredAndProvided ->
                        "User and io.patterueldev.room.Room passcodes are required"
                    !isUserPasscodeRequiredAndProvided ->
                        "User passcode is required"
                    else ->
                        "io.patterueldev.room.Room passcode is required"
                }

                // Return response with passcode requirement flags and message
                return ConnectResponse(
                    success = false,
                    data = ConnectResponseData(
                        requiresUserPasscode = requiresUserPasscode, // Make sure this is true only if passcode is actually needed
                        requiresRoomPasscode = requiresRoomPasscode  // Same here
                    ),
                    status = 400,
                    message = message
                )
            }
        }

        // step4: check if the user passcode is correct
        if (requiresUserPasscode) {
            // This should never happen, since we checked for passcode presence earlier
            val passcode = parameters.userPasscode ?: return GenericResponse.failure("Passcode is required")
            // This should never happen, since we checked for user hash presence earlier
            val userHashedPasscode = user.hashedPasscode ?: return GenericResponse.failure("User does not have a passcode")
            val passcodeMatches = authRepository.matchPasscode(passcode, userHashedPasscode)
            if (!passcodeMatches) {
                return GenericResponse.failure("Passcode is incorrect")
            }
        }

        // step5: check if the room passcode is correct
        if (requiresRoomPasscode) {
            // This should never happen, since we checked for passcode presence earlier
            val passcode = parameters.roomPasscode ?: return GenericResponse.failure("Passcode is required")
            // This should never happen, since we checked for room passcode presence earlier
            val roomPasscode = room.passcode ?: return GenericResponse.failure("io.patterueldev.room.Room does not have a passcode")
            val passcodeMatches = authRepository.matchPasscode(passcode, roomPasscode)
            if (!passcodeMatches) {
                return GenericResponse.failure("Passcode is incorrect")
            }
        }

        // step6: add the user to the room
        val token = authRepository.addUserToRoom(user, room)

        // step6: return success
        return GenericResponse.success(
            ConnectResponseData(
                accessToken = token,
//                refreshToken = "refresh-token"
            )
        )
    }
}
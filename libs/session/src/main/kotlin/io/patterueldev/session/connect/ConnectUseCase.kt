package io.patterueldev.session.connect

import io.patterueldev.session.authuser.AuthUserRepository
import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.session.common.ConnectResponse
import io.patterueldev.session.room.RoomRepository
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase

internal class ConnectUseCase(
    private val roomRepository: RoomRepository,
    private val authUserRepository: AuthUserRepository,
    private val authRepository: AuthRepository,
) : ServiceUseCase<ConnectParameters, ConnectResponse> {
    override suspend fun execute(parameters: ConnectParameters): ConnectResponse {
        println("ConnectUseCase: $parameters")
        // step1: find the room
        val room = roomRepository.findRoomById(parameters.roomId) ?: return GenericResponse.failure("Room not found")
        // step1.1: check if the room is archived
        if (room.isArchived) {
            return GenericResponse.failure("Room is archived")
        }
        // step2: fetch the user
        var user = authUserRepository.findUserByUsername(parameters.username)
        // step2.1: if the user does not exist, create it
        if (user == null) {
            user = authUserRepository.createUser(parameters.username, parameters.userPasscode)
        }
        // step2.2: check if the user is still in the room
        // TODO: check if the user is already in the room; not too required right now, but will be useful in the future

        // step3: check if the user requires a passcode
        val requiresUserPasscode = user.hashedPasscode != null

        // step4: check if the room also requires a passcode
        val requiresRoomPasscode = room.passcode != null

        // Check parameters if passcode(s) were not provided
        if (requiresUserPasscode || requiresRoomPasscode) {
            val bothAreRequired = requiresUserPasscode && requiresRoomPasscode

            val message: String?
            if (bothAreRequired && (parameters.userPasscode == null && parameters.roomPasscode == null)) {
                message = "User and Room passcodes are required"
            } else if (requiresUserPasscode && parameters.userPasscode == null) {
                message = "User passcode is required"
            } else if (requiresRoomPasscode && parameters.roomPasscode == null) {
                message = "Room passcode is required"
            } else {
                message = null
            }

            if (message != null) {
                // Return response with passcode requirement flags and message
                return ConnectResponse(
                    success = false,
                    data =
                        ConnectResponseData(
                            // Make sure this is true only if passcode is actually needed
                            requiresUserPasscode = requiresUserPasscode,
                            // Same here
                            requiresRoomPasscode = requiresRoomPasscode,
                        ),
                    status = 400,
                    message = message,
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
            ),
        )
    }
}

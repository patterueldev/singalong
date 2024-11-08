package io.patterueldev.session.connect

import io.patterueldev.client.ClientType
import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.role.Role
import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.session.authuser.AuthUserRepository
import io.patterueldev.session.common.ConnectResponse
import io.patterueldev.session.room.RoomRepository
import java.time.LocalDateTime

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
            if (!passcodeMatches) return GenericResponse.failure("Passcode is incorrect")
        }

        // step6: verify roles
        when (parameters.clientType) {
            ClientType.CONTROLLER -> {
                val supportedRoles = listOf(Role.USER_GUEST, Role.ADMIN)
                if (user.role !in supportedRoles) return GenericResponse.failure("Host are not allowed to connect as a controller")
            }
            ClientType.PLAYER -> {
                // only the host and admin role is allowed to connect as a player
                val supportedRoles = listOf(Role.USER_HOST, Role.ADMIN)
                if (user.role !in supportedRoles) return GenericResponse.failure("Guest are not allowed to connect as a player")
            }
            ClientType.ADMIN -> {
                // only the admin role is allowed to connect as an admin
                if (user.role != Role.ADMIN) return GenericResponse.failure("Only admin role is allowed to connect as an admin")
            }
        }

        // step7: add the user to the room
        // if the user is connecting as a controller, and if the user is a guest, check if the user is already in the room
        // otherwise, override if the user is an admin or host (although hosts should not be able to connect as a controller)

        if (parameters.clientType == ClientType.CONTROLLER && user.role == Role.USER_GUEST) {
            val userFromRoom = authRepository.checkUserFromRoom(user, room, parameters.clientType)

            // if the user is signing in from a different device, check if the user is already in the room
            println("User from room: $userFromRoom")
            println("deviceId: ${parameters.deviceId}")
            println("userFromRoom.deviceId: ${userFromRoom?.deviceId}")

            if (userFromRoom != null && userFromRoom.deviceId != parameters.deviceId) {
                // check if the user is still connected to the room; maybe via socket, or via session
                // TODO: on sign out, mark the user as disconnected
                if (userFromRoom.isConnected) {
                    // check the connection date
                    // if user last connected within 3 hours, return failure
                    val lastConnectedAt = userFromRoom.lastConnectedAt
                    val now = LocalDateTime.now()
                    if (lastConnectedAt.plusHours(3).isAfter(now)) {
                        return GenericResponse.failure("User is already in the room")
                    }
                }

                // otherwise, ignore and proceed
            }
        }

        val response = authRepository.upsertUserToRoom(user, room, parameters.clientType, parameters.deviceId)

        // step6: return success
        return GenericResponse.success(
            ConnectResponseData(
                accessToken = response.accessToken,
                refreshToken = response.refreshToken,
            ),
        )
    }
}

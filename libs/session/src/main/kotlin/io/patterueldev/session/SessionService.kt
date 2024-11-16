package io.patterueldev.session

import io.patterueldev.auth.AuthRepository
import io.patterueldev.authuser.AuthUserRepository
import io.patterueldev.room.RoomRepository
import io.patterueldev.session.common.ConnectResponse
import io.patterueldev.session.connect.ConnectParameters
import io.patterueldev.session.connect.ConnectUseCase
import io.patterueldev.session.setuserpasscode.SetUserPasscodeParameters
import io.patterueldev.session.setuserpasscode.SetUserPasscodeResponse
import io.patterueldev.session.setuserpasscode.SetUserPasscodeUseCase
import io.patterueldev.session.startorcreateroom.FindOrCreateRoomUseCase

class SessionService(
    val authUserRepository: AuthUserRepository,
    val roomRepository: RoomRepository,
    val authRepository: AuthRepository,
) {
    private val findOrCreateRoomUseCase: FindOrCreateRoomUseCase by lazy { FindOrCreateRoomUseCase(roomRepository) }
    private val connectUseCase: ConnectUseCase by lazy { ConnectUseCase(roomRepository, authUserRepository, authRepository) }
    private val setUserPasscodeUseCase: SetUserPasscodeUseCase by lazy { SetUserPasscodeUseCase(authRepository, authUserRepository) }

    suspend fun getActiveRooms() = roomRepository.findActiveRooms()

    suspend fun getAssignedRoomForPlayer(playerId: String) = roomRepository.findAssignedRoomForPlayer(playerId)

    suspend fun findOrCreateRoom() = findOrCreateRoomUseCase.execute()

    suspend fun connect(parameters: ConnectParameters): ConnectResponse = connectUseCase(parameters)

    suspend fun setUserPasscode(parameters: SetUserPasscodeParameters): SetUserPasscodeResponse = setUserPasscodeUseCase(parameters)
}

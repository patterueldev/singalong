import io.patterueldev.session.auth.AuthRepository
import io.patterueldev.session.common.ConnectResponse
import io.patterueldev.session.connect.ConnectParameters
import io.patterueldev.session.connect.ConnectUseCase
import io.patterueldev.session.room.RoomRepository
import io.patterueldev.session.auth.AuthUserRepository

class SessionService(
    val authUserRepository: AuthUserRepository,
    val roomRepository: RoomRepository,
    val authRepository: AuthRepository
) {
    private val connectUseCase: ConnectUseCase by lazy {
        ConnectUseCase(roomRepository, authUserRepository, authRepository)
    }

    suspend fun connect(parameters: ConnectParameters): ConnectResponse = connectUseCase(parameters)
}
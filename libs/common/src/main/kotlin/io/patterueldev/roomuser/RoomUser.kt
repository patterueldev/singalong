package io.patterueldev.roomuser

import io.patterueldev.client.ClientType
import io.patterueldev.role.Role
import java.time.LocalDateTime

interface RoomUser {
    val username: String
    val roomId: String
    val joinedAt: LocalDateTime
    val role: Role
    val clientType: ClientType
    val deviceId: String
}

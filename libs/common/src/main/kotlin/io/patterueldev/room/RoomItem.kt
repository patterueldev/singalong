package io.patterueldev.room

import java.time.LocalDateTime

interface RoomItem {
    val id: String
    val name: String
    val isSecured: Boolean
    val isActive: Boolean
    val lastActive: LocalDateTime
}

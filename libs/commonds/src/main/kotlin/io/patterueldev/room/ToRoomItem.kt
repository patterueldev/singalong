package io.patterueldev.room

import io.patterueldev.mongods.room.RoomDocument
import java.time.LocalDateTime

fun RoomDocument.toRoomItem(): RoomItem {
    return object : RoomItem {
        override val id: String = this@toRoomItem.id
        override val name: String = this@toRoomItem.name
        override val isSecured: Boolean = this@toRoomItem.passcode != null
        override val isActive: Boolean = this@toRoomItem.archivedAt == null
        override val lastActive: LocalDateTime = this@toRoomItem.lastActiveAt
    }
}

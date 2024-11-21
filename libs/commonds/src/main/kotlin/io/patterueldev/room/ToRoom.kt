package io.patterueldev.room

import io.patterueldev.mongods.room.RoomDocument

fun RoomDocument.toRoom(): Room {
    return object : Room {
        override val id: String = this@toRoom.id
        override val name: String = this@toRoom.name
        override val passcode: String? = this@toRoom.passcode
        override val isArchived: Boolean = this@toRoom.archivedAt != null

        override fun toString(): String {
            return "Room(id=$id, name=$name, passcode=$passcode, isArchived=$isArchived)"
        }
    }
}
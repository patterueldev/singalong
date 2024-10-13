package io.patterueldev.session.room

import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.room.RoomDocumentRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component
import org.springframework.stereotype.Repository
import kotlin.random.Random

@Repository
open class RoomRepositoryDS : RoomRepository {
    @Autowired private lateinit var roomDocumentRepository: RoomDocumentRepository

    @Autowired private lateinit var sixDigitIdGenerator: SixDigitIdGenerator

    override fun findRoomById(roomId: String): Room? {
        val roomDocument = roomDocumentRepository.findRoomById(roomId) ?: return null
        return roomDocument.toRoom()
    }

    override fun findActiveRoom(): Room? {
        val roomDocument = roomDocumentRepository.findActiveRoom() ?: return null
        return roomDocument.toRoom()
    }

    override fun createRoom(): Room {
        val rooms = roomDocumentRepository.findAll()
        val existingRoomIds = rooms.map { it.id }
        val id = sixDigitIdGenerator.generateUnique(existingRoomIds)
        val count = rooms.count()
        val roomDocument =
            roomDocumentRepository.insert(
                RoomDocument(
                    id = id,
                    name = "Room $count",
                ),
            )
        return roomDocument.toRoom()
    }
}

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

// TODO: Move this to a common module and enhance it
@Component
internal class SixDigitIdGenerator {
    fun generate(): String {
        return Random.nextInt(100000, 999999).toString()
    }

    fun generateUnique(existingIds: List<String>): String {
        var id = generate()
        while (id in existingIds) {
            id = generate()
        }
        return id
    }
}

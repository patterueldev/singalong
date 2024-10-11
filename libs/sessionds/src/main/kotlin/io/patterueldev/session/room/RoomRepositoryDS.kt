package io.patterueldev.session.room

import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.room.RoomDocumentRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service

@Service
class RoomRepositoryDS : RoomRepository {
    @Autowired private lateinit var roomDocumentRepository: RoomDocumentRepository

    override fun findRoomById(roomId: String): Room? {
        val roomDocument = roomDocumentRepository.findRoomById(roomId) ?: return null
        return object : Room {
            override val id: String = roomDocument.id
            override val name: String = roomDocument.name
            override val passcode: String? = roomDocument.passcode
            override val isArchived: Boolean = roomDocument.archivedAt != null
        }
    }
}

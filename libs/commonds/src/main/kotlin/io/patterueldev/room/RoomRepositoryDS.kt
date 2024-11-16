package io.patterueldev.room

import io.patterueldev.common.PaginatedData
import io.patterueldev.common.Pagination
import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.room.RoomDocumentRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Component
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import kotlin.random.Random

@Repository
open class RoomRepositoryDS : RoomRepository {
    @Autowired private lateinit var roomDocumentRepository: RoomDocumentRepository

    @Autowired private lateinit var sixDigitIdGenerator: SixDigitIdGenerator

    override suspend fun newRoomId(): String {
        val rooms = roomDocumentRepository.findAll()
        val existingRoomIds = rooms.map { it.id }
        return sixDigitIdGenerator.generateUnique(existingRoomIds)
    }

    override suspend fun findRoomById(roomId: String): Room? {
        val roomDocument = roomDocumentRepository.findRoomById(roomId) ?: return null
        return roomDocument.toRoom()
    }

    override suspend fun findActiveRoom(): Room? {
        println("Finding active room")
        val roomDocument = roomDocumentRepository.findActiveRoom() ?: return null
        println("Found active room: $roomDocument")
        return roomDocument.toRoom()
    }

    override suspend fun findActiveRooms(): List<Room> {
        return roomDocumentRepository.findActiveRooms().map { it.toRoom() }
    }

    override suspend fun findAssignedRoomForPlayer(playerId: String): Room? {
        println("Finding assigned room for player: $playerId")
        val roomDocument = roomDocumentRepository.findAssignedRoomsForPlayer(playerId).firstOrNull() ?: return null
        println("Found assigned room for player: $roomDocument")
        return roomDocument.toRoom()
    }

    override suspend fun createRoom(parameters: CreateRoomParameters?): Room {
        val id: String
        val name: String
        val passcode: String?
        if (parameters == null) {
            id = newRoomId()
            name = "Room $id"
            passcode = null
        } else {
            id = parameters.roomId
            name = parameters.roomName
            passcode = parameters.roomPasscode.trim().ifBlank { null }
        }
        val roomDocument =
            roomDocumentRepository.insert(
                RoomDocument(
                    id = id,
                    name = name,
                    passcode = passcode,
                ),
            )
        return roomDocument.toRoom()
    }

    override suspend fun loadRoomList(
        limit: Int,
        keyword: String?,
        page: Pagination?,
    ): PaginatedRoomList {
        // only support PagePagination
        return try {
            // always paginate; and received page is based on 1-index
            // so if page is 0 or below, it's not a valid page; or do a minmax so if page is less than or equal to 0, it's 1
            var pageNumber = 1
            if (page != null) {
                when (page) {
                    is Pagination.PagePagination -> {
                        pageNumber = maxOf(1, page.pageNumber)
                    }
                    else -> {
                        throw IllegalArgumentException("Use `page` only for pagination")
                    }
                }
            }
            val pageable: Pageable = Pageable.ofSize(limit).withPage(pageNumber - 1)
            val pagedRoomsResult: Page<RoomDocument>
            if (keyword == null) {
                pagedRoomsResult = roomDocumentRepository.findAllExceptPreadded(pageable)
            } else {
                pagedRoomsResult =
                    withContext(Dispatchers.IO) {
                        roomDocumentRepository.findByKeywordExceptPreadded(
                            keyword, pageable,
                        )
                    }
            }
            val songs =
                pagedRoomsResult.content.map {
                    it.toRoomItem()
                }
            val totalPages = pagedRoomsResult.totalPages // e.g. 1
            val currentPage = pagedRoomsResult.pageable.pageNumber // e.g. 0
            val nextPage = currentPage + 1 // e.g. 1
            if (nextPage >= totalPages) { // gt or eq is a bit excessive since ideally it should be eq; but doesn't hurt to be safe
                PaginatedData.lastPage(songs)
            } else {
                val nextPageBase1 = nextPage + 1
                PaginatedData.withNextPage(songs, nextPageBase1)
            }
        } catch (e: Exception) {
            println("Error loading rooms: $e")
            throw e
        }
    }

    override suspend fun assignPlayerToRoom(
        playerId: String,
        roomId: String,
    ) {
        // pull the room
        val roomDocument = roomDocumentRepository.findRoomById(roomId) ?: return

        // assign the player to the room
        roomDocument.assignedPlayerId = playerId

        roomDocumentRepository.save(roomDocument)
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
        val maxRetries = 100
        var retries = 0
        while (existingIds.contains(id) && retries < maxRetries) {
            id = generate()
            retries++
        }
        if (retries >= maxRetries) {
            throw IllegalStateException("Failed to generate a unique id")
        }
        return id
    }
}

fun RoomDocument.toRoomItem(): RoomItem {
    return object : RoomItem {
        override val id: String = this@toRoomItem.id
        override val name: String = this@toRoomItem.name
        override val isSecured: Boolean = this@toRoomItem.passcode != null
        override val isActive: Boolean = this@toRoomItem.archivedAt == null
        override val lastActive: LocalDateTime = this@toRoomItem.lastActiveAt
    }
}

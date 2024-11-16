package io.patterueldev.mongods.room

import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface RoomDocumentRepository : MongoRepository<RoomDocument, String> {
    @Query("{ 'id': ?0 }")
    fun findRoomById(
        @Param("id") roomId: String,
    ): RoomDocument?

    @Query(
        value = "{ 'archivedAt': null, '_id': { '\$nin': ['idle', 'admin'] } }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findActiveRoom(): RoomDocument?

    @Query(
        value = "{ 'archivedAt': null, '_id': { '\$nin': ['idle', 'admin'] } }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findActiveRooms(): List<RoomDocument>

    @Query(
        value = "{ 'archivedAt': null, 'assignedPlayerId': ?0 }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findAssignedRoomsForPlayer(
        playerId: String,
    ): List<RoomDocument>

    @Query(
        value = "{ '\$or': [ { 'name': { '\$regex': ?0, '\$options': 'i' } }, { '_id': { '\$regex': ?0, '\$options': 'i' } } ] }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findByKeyword(
        keyword: String,
        pageable: Pageable,
    ): Page<RoomDocument>

    @Query(
        value = "{ '_id': { '\$nin': ['admin', 'idle'] } }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findAllExceptPreadded(pageable: Pageable): Page<RoomDocument>

    @Query(
        value = "{ '\$or': [ { 'name': { '\$regex': ?0, '\$options': 'i' } }, { '_id': { '\$regex': ?0, '\$options': 'i' } } ], '_id': { '\$nin': ['admin', 'idle'] } }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findByKeywordExceptPreadded(
        keyword: String,
        pageable: Pageable,
    ): Page<RoomDocument>
}

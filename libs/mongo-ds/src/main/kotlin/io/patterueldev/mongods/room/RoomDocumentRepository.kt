package io.patterueldev.mongods.room

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
        value = "{ 'archivedAt': null, 'id': { '\$ne': 'admin' } }",
        sort = "{ 'createdAt': -1 }",
    )
    fun findActiveRoom(): RoomDocument?
}

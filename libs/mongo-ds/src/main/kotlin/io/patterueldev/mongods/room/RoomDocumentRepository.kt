package io.patterueldev.mongods.room

import io.patterueldev.mongods.song.SongDocument
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface RoomDocumentRepository: MongoRepository<RoomDocument, String> {
    @Query("{ 'id': ?0 }")
    fun findRoomById(@Param("id") roomId: String): RoomDocument?
}
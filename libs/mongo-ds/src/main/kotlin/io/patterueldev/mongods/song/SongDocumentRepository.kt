package io.patterueldev.mongods.song

import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface SongDocumentRepository : MongoRepository<SongDocument, String> {
    // Query for matching songTitle and songArtist
    @Query("{ '\$or': [ { 'title': { '\$regex': ?0, '\$options': 'i' } }, { 'artist': { '\$regex': ?0, '\$options': 'i' } } ] }")
    fun findByKeyword(
        keyword: String,
        pageable: Pageable,
    ): Page<SongDocument>

    // Query for matching sourceId
    @Query("{ 'sourceId': ?0 }")
    fun findBySourceId(sourceId: String): SongDocument?
}

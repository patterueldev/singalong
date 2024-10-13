package io.patterueldev.mongods.song

import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface SongDocumentRepository : MongoRepository<SongDocument, String> {
    // Query for matching songTitle and songArtist
    @Query("{ '\$or': [ { 'songTitle': { '\$regex': ?0, '\$options': 'i' } }, { 'songArtist': { '\$regex': ?1, '\$options': 'i' } } ] }")
    fun findByTitleAndArtist(
        @Param("title") title: String,
        @Param("artist") artist: String,
        pageable: Pageable,
    ): Page<SongDocument>
}

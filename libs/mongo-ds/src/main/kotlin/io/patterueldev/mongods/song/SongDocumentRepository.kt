package io.patterueldev.mongods.song

import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.mongodb.repository.Aggregation
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface SongDocumentRepository : MongoRepository<SongDocument, String> {
    @Query("{ 'archivedAt': null }")
    fun findAllUnarchived(pageable: Pageable): Page<SongDocument>

    // Query for matching songTitle and songArtist
    @Query("{ '\$or': [ { 'title': { '\$regex': ?0, '\$options': 'i' } }, { 'artist': { '\$regex': ?0, '\$options': 'i' } } ] }")
    fun findByKeyword(
        keyword: String,
        pageable: Pageable,
    ): Page<SongDocument>

    @Query(
        """
    { 
        '${'$'}or': [ 
            { 'title': { '${'$'}regex': ?0, '${'$'}options': 'i' } }, 
            { 'artist': { '${'$'}regex': ?0, '${'$'}options': 'i' } }, 
            { 'tags': { '${'$'}regex': ?0, '${'$'}options': 'i' } },
            { 'genres': { '${'$'}regex': ?0, '${'$'}options': 'i' } }
        ], 
        'archivedAt': null 
    }
    """
    )
    fun findUnarchivedByKeyword(
        keyword: String,
        pageable: Pageable,
    ): Page<SongDocument>

    // Query for matching sourceId
    @Query("{ 'sourceId': ?0 }")
    fun findBySourceId(sourceId: String): SongDocument?

    @Query("{ 'sourceId': ?0 }")
    fun findAllBySourceId(sourceId: String): List<SongDocument>

    @Query(
        value = "{ 'id': { '\$nin': ?0 } }",
        sort = "{ 'title': 1 }"
    )
    fun findAllNotInIds(ids: List<String>, pageable: Pageable): Page<SongDocument>

    @Query(
        value = "{ 'archivedAt': null, 'id': { '\$nin': ?0 } }",
        sort = "{ 'title': 1 }"
    )
    fun findAllUnarchivedNotInIds(ids: List<String>, pageable: Pageable): Page<SongDocument>

    @Query(
        value = "{ '\$or': [ { 'title': { '\$regex': ?0, '\$options': 'i' } }, { 'artist': { '\$regex': ?0, '\$options': 'i' } } ], 'id': { '\$nin': ?1 } }",
        sort = "{ 'title': 1 }"
    )
    fun findByKeywordNotInIds(keyword: String, ids: List<String>, pageable: Pageable): Page<SongDocument>

    @Query(
        value = "{ '\$or': [ { 'title': { '\$regex': ?0, '\$options': 'i' } }, { 'artist': { '\$regex': ?0, '\$options': 'i' } } ], 'archivedAt': null, 'id': { '\$nin': ?1 } }",
        sort = "{ 'title': 1 }"
    )
    fun findUnarchivedByKeywordNotInIds(keyword: String, ids: List<String>, pageable: Pageable): Page<SongDocument>

}

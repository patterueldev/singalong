package io.patterueldev.mongods.reservedsong

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import org.springframework.data.mongodb.repository.Aggregation
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Document(collection = "reservedSong")
data class ReservedSongDocument(
    @Id val id: String? = null,
    val songId: String,
    val roomId: String,
    val order: Int,
    val reservedBy: String,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
    // indicates that the song started playing
    val startedPlayingAt: LocalDateTime? = null,
    // indicates that the song was played
    val finishedPlayingAt: LocalDateTime? = null,
)

@Repository
interface ReservedSongDocumentRepository : MongoRepository<ReservedSongDocument, String> {
    @Query(
        value = "{ 'roomId' : ?0, 'startedPlayingAt': null, 'finishedPlayingAt' : null }",
        sort = "{ 'order' : 1 }",
    )
    fun loadUnplayedReservedSongs(roomId: String): List<ReservedSongDocument>

    @Query(
        value = "{ 'roomId' : ?0, 'startedPlayingAt': { \$ne: null }, 'finishedPlayingAt' : null }",
    )
    fun loadPlayingReservedSong(roomId: String): ReservedSongDocument?

    @Aggregation(
        pipeline = [
            "{ \$match: { 'roomId' : ?0 } }",
            "{ \$group: { _id: '\$roomId', maxOrder: { \$max: '\$order' } } }",
        ],
    )
    fun findMaxOrder(roomId: String): Int
}
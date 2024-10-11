package io.patterueldev.mongods.reservedsong

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository

@Document(collection = "reservedSong")
data class ReservedSongDocument(
    @Id val id: String? = null,
    val songId: String,
    val roomId: String,
    val order: Int,
    val reservedBy: String,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
    val finishedPlayingAt: LocalDateTime? = null
)

@Repository
interface ReservedSongDocumentRepository : MongoRepository<ReservedSongDocument, String> {
    @Query(
        value = "{ 'roomId' : ?0, 'finishedPlayingAt' : null }",
        sort = "{ 'order' : 1 }",
    )
    fun loadReservedSongs(roomId: String): List<ReservedSongDocument>
}
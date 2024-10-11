package io.patterueldev.mongods.reservedsong

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "reservedSong")
data class ReversedSongDocument(
    @Id val id: String? = null,
    val songId: String,
    val sessionId: String,
    val orderNumber: Int,
    val reservedBy: String,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
)

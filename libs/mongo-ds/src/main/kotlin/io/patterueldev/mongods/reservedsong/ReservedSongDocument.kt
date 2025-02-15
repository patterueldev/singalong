package io.patterueldev.mongods.reservedsong

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "reservedSong")
data class ReservedSongDocument(
    @Id val id: String? = null,
    val songId: String,
    val roomId: String,
    var order: Int,
    val reservedBy: String,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
    // indicates that the song started playing
    val startedPlayingAt: LocalDateTime? = null,
    // indicates that the song was played
    val finishedPlayingAt: LocalDateTime? = null,
    val completed: Boolean = false, // indicates that the song was played to the end
    var canceledAt: LocalDateTime? = null,
)

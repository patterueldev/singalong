package io.patterueldev.mongods.song

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "song")
data class SongDocument(
    @Id val id: String? = null,
    // if this is null, then the song is not yet downloaded
    val filename: String? = null,
    val source: String,
    val sourceId: String,
    val imageUrl: String,
    val title: String,
    val artist: String,
    val language: String,
    val isOffVocal: Boolean,
    val videoHasLyrics: Boolean,
    val songLyrics: String,
    val lengthSeconds: Int,
    val metadata: Map<String, String>,
    // this should be nullable, but, for simplicity, we will assume that the song is always added by someone
    val addedBy: String,
    // this will be the session id where the song was added; 'admin' if added by an admin somewhere else
    val addedAtSession: String,
    val lastModifiedBy: String,
    @CreatedDate val createdAt: LocalDateTime? = null,
    @LastModifiedDate val updatedAt: LocalDateTime? = null,
) {
    companion object {
        fun new(
            filename: String? = null,
            source: String,
            sourceId: String,
            imageUrl: String,
            title: String,
            artist: String,
            language: String,
            isOffVocal: Boolean,
            videoHasLyrics: Boolean,
            songLyrics: String,
            lengthSeconds: Int,
            metadata: Map<String, String>,
            addedBy: String,
            addedAtSession: String,
            lastModifiedBy: String,
        ) = SongDocument(
            filename = filename,
            source = source,
            sourceId = sourceId,
            imageUrl = imageUrl,
            title = title,
            artist = artist,
            language = language,
            isOffVocal = isOffVocal,
            videoHasLyrics = videoHasLyrics,
            songLyrics = songLyrics,
            lengthSeconds = lengthSeconds,
            metadata = metadata,
            addedBy = addedBy,
            addedAtSession = addedAtSession,
            lastModifiedBy = lastModifiedBy,
        )
    }
}

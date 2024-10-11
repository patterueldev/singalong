package io.patterueldev.mongods.room

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "room")
data class RoomDocument(
    // for simplicity, we will use the session id as the document id; this will be generated strategically making sure that the session id is unique, and just a few characters long
    // 6 digit number
    @Id val id: String,
    val name: String,
    // nullable because the session might not have a passcode
    val passcode: String? = null,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
    val archivedAt: LocalDateTime? = null,
)

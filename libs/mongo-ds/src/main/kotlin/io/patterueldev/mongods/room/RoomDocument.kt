package io.patterueldev.mongods.room

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "session")
data class RoomDocument(
    // for simplicity, we will use the session id as the document id; this will be generated strategically making sure that the session id is unique, and just a few characters long
    @Id val id: String, // 6 digit number
    val name: String,
    val passcode: String?, // nullable because the session might not have a passcode
    @CreatedDate val createdAt: LocalDateTime,
    @LastModifiedDate val updatedAt: LocalDateTime
)
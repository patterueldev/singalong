package io.patterueldev.mongods.session

import java.time.LocalDateTime
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document

@Document(collection = "session")
data class SessionDocument(
    @Id val id: String, // for simplicity, we will use the session id as the document id; this will be generated strategically making sure that the session id is unique, and just a few characters long
    val sessionName: String,
    val passcode: String?, // nullable because the session might not have a passcode
    @CreatedDate val createdAt: LocalDateTime,
    @LastModifiedDate val updatedAt: LocalDateTime
)

package io.patterueldev.mongods.session

import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.user.UserDocument
import java.time.LocalDateTime
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.DBRef
import org.springframework.data.mongodb.core.mapping.Document
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.stereotype.Repository

@Document(collection = "session")
data class SessionDocument(
    @Id val id: String? = null,
    @DBRef val userDocument: UserDocument,
    @DBRef val roomDocument: RoomDocument,
    @CreatedDate val createdAt: LocalDateTime? = null,
)

@Repository
interface SessionDocumentRepository: MongoRepository<SessionDocument, String>
package io.patterueldev.mongods.session

import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.user.UserDocument
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.mongodb.core.mapping.DBRef
import org.springframework.data.mongodb.core.mapping.Document
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Document(collection = "session")
data class SessionDocument(
    @Id val id: String? = null,
    @DBRef val userDocument: UserDocument,
    @DBRef val roomDocument: RoomDocument,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
)

@Repository
interface SessionDocumentRepository : MongoRepository<SessionDocument, String>

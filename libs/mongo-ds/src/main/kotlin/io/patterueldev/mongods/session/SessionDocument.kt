package io.patterueldev.mongods.session

import io.patterueldev.client.ClientType
import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.user.UserDocument
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.DBRef
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "session")
data class SessionDocument(
    @Id val id: String? = null,
    @DBRef val userDocument: UserDocument,
    @DBRef val roomDocument: RoomDocument,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
    // for indexing
    var deviceId: String = "",
    var lastConnectedAt: LocalDateTime = LocalDateTime.now().minusDays(7),
    var isConnected: Boolean = true,
    var connectedOnClient: ClientType = ClientType.CONTROLLER,
    val lastCheckedDate: LocalDateTime = LocalDateTime.now(),
)

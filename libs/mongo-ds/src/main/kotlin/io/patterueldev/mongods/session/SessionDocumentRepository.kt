package io.patterueldev.mongods.session

import io.patterueldev.client.ClientType
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface SessionDocumentRepository : MongoRepository<SessionDocument, String> {
    @Query("{ 'userDocument.\$id' : ?0, 'roomDocument.\$id' : ?1, 'connectedOnClient' : ?2 }")
    fun findBy(
        username: String,
        roomId: String,
        clientType: ClientType,
    ): SessionDocument?

    @Query("{ 'roomDocument.\$id' : ?0 }")
    fun findSessionsByRoom(roomId: String): List<SessionDocument>
}

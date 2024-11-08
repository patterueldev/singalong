package io.patterueldev.mongods.session

import io.patterueldev.client.ClientType
import io.patterueldev.mongods.room.RoomDocument
import io.patterueldev.mongods.user.UserDocument
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.mongodb.repository.Update
import org.springframework.stereotype.Repository

@Repository
interface SessionDocumentRepository : MongoRepository<SessionDocument, String> {
    @Query("{ 'userDocument.\$id' : ?0, 'roomDocument.\$id' : ?1, 'connectedOnClient' : ?2 }")
    fun findBy(username: String, roomId: String, clientType: ClientType): SessionDocument?
}

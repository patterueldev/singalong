package io.patterueldev.mongods.user

import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface UserDocumentRepository : MongoRepository<UserDocument, String> {
    @Query("{ 'username': ?0 }")
    fun findByUsername(username: String): UserDocument?

    @Query("{ 'username': { \$in: ?0 } }")
    fun findByUsernames(usernames: List<String>): List<UserDocument>
}

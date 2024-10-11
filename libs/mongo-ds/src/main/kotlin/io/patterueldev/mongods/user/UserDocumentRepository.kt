package io.patterueldev.mongods.user

import io.patterueldev.role.Role
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.mongodb.repository.Update
import org.springframework.stereotype.Repository

@Repository
interface UserDocumentRepository : MongoRepository<UserDocument, String> {
    @Query("{ 'username': ?0 }")
    fun findByUsername(username: String): UserDocument?
}

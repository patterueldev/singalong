package io.patterueldev.mongods.session

import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.stereotype.Repository

@Repository
interface SessionDocumentRepository : MongoRepository<SessionDocument, String>

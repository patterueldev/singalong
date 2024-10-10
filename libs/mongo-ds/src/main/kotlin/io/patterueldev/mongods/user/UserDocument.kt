package io.patterueldev.mongods.user

import java.time.LocalDateTime
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document

@Document(collection = "user")
data class UserDocument(
    @Id val username: String, // for simplicity, we will use the username directly
    val passcode: String?, // nullable, because the user might not have a passcode; can be used by any user to authenticate if not protected by a passcode
    @CreatedDate val createdAt: LocalDateTime? = null,
    @LastModifiedDate val updatedAt: LocalDateTime? = null,
)

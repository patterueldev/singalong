package io.patterueldev.mongods.user

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "user")
data class UserDocument(
    // for simplicity, we will use the username directly
    @Id val username: String,
    // nullable, because the user might not have a passcode; can be used by any user to authenticate if not protected by a passcode
    val passcode: String?,
    @CreatedDate val createdAt: LocalDateTime? = null,
    @LastModifiedDate val updatedAt: LocalDateTime? = null,
)

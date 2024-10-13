package io.patterueldev.mongods.user

import io.patterueldev.role.Role
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
    var passcode: String?,
    var role: Role = Role.USER_GUEST,
    @CreatedDate val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate val updatedAt: LocalDateTime = LocalDateTime.now(),
)

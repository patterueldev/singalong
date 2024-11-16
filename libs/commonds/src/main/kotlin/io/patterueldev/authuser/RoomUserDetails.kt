package io.patterueldev.authuser

import io.patterueldev.client.ClientType
import io.patterueldev.mongods.user.UserDocument
import io.patterueldev.role.Role
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails

data class RoomUserDetails(
    val user: UserDocument,
    val roomId: String,
    val deviceId: String,
    val role: Role,
    val clientType: ClientType,
    val rawAuthorities: Collection<GrantedAuthority>,
) : UserDetails {
    override fun getAuthorities(): Collection<GrantedAuthority> {
        return rawAuthorities
    }

    override fun getPassword(): String {
        return user.passcode ?: ""
    }

    override fun getUsername(): String {
        return user.username
    }
}

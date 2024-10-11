package io.patterueldev.session.room

import io.patterueldev.mongods.user.UserDocument
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails

data class RoomUserDetails(
    val user: UserDocument,
    val roomId: String,
    val rawAuthorities: Collection<GrantedAuthority>
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
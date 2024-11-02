package io.patterueldev.role

import org.junit.jupiter.api.Assertions.assertArrayEquals
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

class RoleTest {
    @Test
    fun valueOf_withValidRoleName_returnsCorrectEnum() {
        val role = Role.valueOf("ADMIN")
        assertEquals(Role.ADMIN, role)
    }

    @Test
    fun valueOf_withInvalidRoleName_throwsIllegalArgumentException() {
        assertThrows<IllegalArgumentException> {
            Role.valueOf("INVALID_ROLE")
        }
    }

    @Test
    fun values_returnsAllRoles() {
        val roles = Role.entries.toTypedArray()
        assertArrayEquals(arrayOf(Role.ADMIN, Role.USER_HOST, Role.USER_GUEST), roles)
    }
}

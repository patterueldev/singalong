package io.patterueldev.client

import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class ClientTypeTest {
    @Test
    fun `test ClientType values`() {
        val expectedValues = arrayOf(ClientType.ADMIN, ClientType.CONTROLLER, ClientType.PLAYER)
        val actualValues = ClientType.entries.toTypedArray()
        Assertions.assertEquals(expectedValues.size, actualValues.size)
        Assertions.assertEquals(expectedValues.toList(), actualValues.toList())
    }
}

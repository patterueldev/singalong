import io.patterueldev.common.GenericResponse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class GenericResponseTest {
    @Test
    fun `test success response`() {
        val data = "Test Data"
        val response = GenericResponse.success(data)

        assertEquals(true, response.success)
        assertEquals(200, response.status)
        assertEquals(data, response.data)
        assertEquals(null, response.message)
    }

    @Test
    fun `test failure response`() {
        val message = "Error occurred"
        val response = GenericResponse.failure<String>(message)

        assertEquals(false, response.success)
        assertEquals(500, response.status)
        assertEquals(null, response.data)
        assertEquals(message, response.message)
    }
}

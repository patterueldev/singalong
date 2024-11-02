package io.patterueldev.common

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class GenericNoParametersUseCaseTest {
    class TestGenericNoParametersUseCase : GenericNoParametersUseCase<String> {
        override suspend fun execute(): GenericResponse<String> {
            return GenericResponse.success("No Parameters Result")
        }
    }

    @Test
    fun execute_returnsSuccessResponse() =
        runBlocking {
            val useCase = TestGenericNoParametersUseCase()
            val result = useCase.execute()
            assertTrue(result.success)
            assertEquals(200, result.status)
            assertEquals("No Parameters Result", result.data)
            assertNull(result.message)
        }

    @Test
    fun execute_returnsFailureResponse() =
        runBlocking {
            val useCase =
                object : GenericNoParametersUseCase<String> {
                    override suspend fun execute(): GenericResponse<String> {
                        return GenericResponse.failure("Error occurred")
                    }
                }
            val result = useCase.execute()
            assertFalse(result.success)
            assertEquals(500, result.status)
            assertNull(result.data)
            assertEquals("Error occurred", result.message)
        }
}

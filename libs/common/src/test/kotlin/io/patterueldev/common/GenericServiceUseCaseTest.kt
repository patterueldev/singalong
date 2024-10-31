package io.patterueldev.common

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class GenericServiceUseCaseTest {

    class TestGenericServiceUseCase : GenericServiceUseCase<Int, String> {
        override suspend fun execute(parameters: Int): GenericResponse<String> {
            return if (parameters >= 0) {
                GenericResponse.success("Result: $parameters")
            } else {
                GenericResponse.failure("Negative parameter")
            }
        }
    }

    @Test
    fun execute_withPositiveParameter_returnsSuccessResponse() = runBlocking {
        val useCase = TestGenericServiceUseCase()
        val result = useCase.execute(5)
        Assertions.assertTrue(result.success)
        Assertions.assertEquals(200, result.status)
        Assertions.assertEquals("Result: 5", result.data)
        Assertions.assertNull(result.message)
    }

    @Test
    fun execute_withNegativeParameter_returnsFailureResponse() = runBlocking {
        val useCase = TestGenericServiceUseCase()
        val result = useCase.execute(-1)
        Assertions.assertFalse(result.success)
        Assertions.assertEquals(500, result.status)
        Assertions.assertNull(result.data)
        Assertions.assertEquals("Negative parameter", result.message)
    }

    @Test
    fun execute_withZeroParameter_returnsSuccessResponse() = runBlocking {
        val useCase = TestGenericServiceUseCase()
        val result = useCase.execute(0)
        Assertions.assertTrue(result.success)
        Assertions.assertEquals(200, result.status)
        Assertions.assertEquals("Result: 0", result.data)
        Assertions.assertNull(result.message)
    }
}
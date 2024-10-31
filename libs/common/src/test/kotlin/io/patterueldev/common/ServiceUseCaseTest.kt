package io.patterueldev.common

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class ServiceUseCaseTest {

    class TestServiceUseCase : ServiceUseCase<Int, String> {
        override suspend fun execute(parameters: Int): String {
            return "Result: $parameters"
        }
    }

    @Test
    fun execute_returnsExpectedResult() = runBlocking {
        val useCase = TestServiceUseCase()
        val result = useCase.execute(5)
        Assertions.assertEquals("Result: 5", result)
    }

    @Test
    fun invokeOperator_returnsExpectedResult() = runBlocking {
        val useCase = TestServiceUseCase()
        val result = useCase(10)
        Assertions.assertEquals("Result: 10", result)
    }

    @Test
    fun execute_withNegativeParameter_returnsExpectedResult() = runBlocking {
        val useCase = TestServiceUseCase()
        val result = useCase.execute(-1)
        Assertions.assertEquals("Result: -1", result)
    }

    @Test
    fun execute_withZeroParameter_returnsExpectedResult() = runBlocking {
        val useCase = TestServiceUseCase()
        val result = useCase.execute(0)
        Assertions.assertEquals("Result: 0", result)
    }
}
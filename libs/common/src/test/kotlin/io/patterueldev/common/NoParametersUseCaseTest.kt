package io.patterueldev.common

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class NoParametersUseCaseTest {

    class TestNoParametersUseCase : NoParametersUseCase<String> {
        override suspend fun execute(): String {
            return "No Parameters Result"
        }
    }

    @Test
    fun execute_returnsExpectedResult() = runBlocking {
        val useCase = TestNoParametersUseCase()
        val result = useCase.execute()
        Assertions.assertEquals("No Parameters Result", result)
    }

    @Test
    fun invokeOperator_returnsExpectedResult() = runBlocking {
        val useCase = TestNoParametersUseCase()
        val result = useCase()
        Assertions.assertEquals("No Parameters Result", result)
    }
}
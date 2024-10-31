package io.patterueldev.common

interface ServiceUseCase<P, R> {
    suspend fun execute(parameters: P): R

    suspend operator fun invoke(parameters: P): R {
        return execute(parameters)
    }
}


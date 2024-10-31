package io.patterueldev.common

interface NoParametersUseCase<R> : ServiceUseCase<Unit, R> {
    suspend fun execute(): R

    override suspend fun execute(parameters: Unit): R {
        return execute()
    }

    suspend operator fun invoke(): R {
        return execute()
    }
}
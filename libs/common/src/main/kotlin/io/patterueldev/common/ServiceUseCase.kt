package io.patterueldev.common

interface ServiceUseCase<P, R> {
    suspend fun execute(parameters: P): R

    suspend operator fun invoke(parameters: P): R {
        return execute(parameters)
    }
}

class NoParameters

interface NoParametersUseCase<R> : ServiceUseCase<NoParameters, R> {
    suspend fun execute(): R

    override suspend fun execute(parameters: NoParameters): R {
        return execute()
    }

    suspend operator fun invoke(): R {
        return execute()
    }
}

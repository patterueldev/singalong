package io.patterueldev.common

interface GenericServiceUseCase<P, R> : ServiceUseCase<P, GenericResponse<R>>

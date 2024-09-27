package io.patterueldev.shared

data class GenericResponse<T>(
    val success: Boolean,
    val status: Int,
    val data: T?,
    val message: String?,
) {
    companion object {
        fun <T> success(data: T, status: Int = 200): GenericResponse<T> {
            return GenericResponse(
                success = true,
                status = status,
                data = data,
                message = null
            )
        }

        fun <T> failure(message: String, status: Int = 500): GenericResponse<T> {
            return GenericResponse(
                success = false,
                status = status,
                data = null,
                message = message
            )
        }
    }
}
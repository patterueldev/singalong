package io.patterueldev.common

data class BucketFile(
    val bucket: String,
    val objectName: String,
) {
    fun path() = "$bucket/$objectName"

    companion object {
        fun default(bucket: String) =
            BucketFile(
                bucket = bucket,
                objectName = "default.jpg",
            )
    }
}

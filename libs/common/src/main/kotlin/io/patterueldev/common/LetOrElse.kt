package io.patterueldev.common

fun <T> T?.letOrElse(default: T): T {
    if (this is String?) {
        return this.let { if (it.isNullOrBlank()) default else it }
    }
    if (this is List<*>?) {
        return this.let { if (it.isNullOrEmpty()) default else it }
    }
    return this ?: default
}

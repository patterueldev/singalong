package io.patterueldev.room.common

import org.springframework.stereotype.Component
import kotlin.random.Random

// TODO: Move this to a common module and enhance it
@Component
internal class SixDigitIdGenerator {
    fun generate(): String {
        return Random.nextInt(100000, 999999).toString()
    }

    fun generateUnique(existingIds: List<String>): String {
        var id = generate()
        val maxRetries = 100
        var retries = 0
        while (existingIds.contains(id) && retries < maxRetries) {
            id = generate()
            retries++
        }
        if (retries >= maxRetries) {
            throw IllegalStateException("Failed to generate a unique id")
        }
        return id
    }
}

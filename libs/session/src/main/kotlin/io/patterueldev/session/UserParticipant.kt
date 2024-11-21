package io.patterueldev.session

import java.time.LocalDateTime

abstract class UserParticipant(
    val songsFinished: Int
) {
    abstract val name: String
    abstract val joinedAt: Long

}
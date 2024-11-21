package io.patterueldev.session

abstract class UserParticipant(
    val songsFinished: Int,
) {
    abstract val name: String
    abstract val joinedAt: Long
}

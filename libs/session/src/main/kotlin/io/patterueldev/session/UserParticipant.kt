package io.patterueldev.session

abstract class UserParticipant(
    val songsFinished: Int,
    val songsUpcoming: Int,
) {
    abstract val name: String
    abstract val joinedAt: Long
}

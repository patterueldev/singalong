package io.patterueldev.reservation.currentsong

abstract class CurrentSong {
    abstract val id: String
    abstract val title: String
    abstract val artist: String
    abstract val thumbnailPath: String
    abstract val videoPath: String
    abstract val durationInSeconds: Int
    abstract val reservingUser: String
    abstract val lyrics: String
    var volume: Double = 1.0
}

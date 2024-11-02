package io.patterueldev.reservation.currentsong

interface CurrentSong {
    val id: String
    val title: String
    val artist: String
    val thumbnailPath: String
    val videoPath: String
    val reservingUser: String
}

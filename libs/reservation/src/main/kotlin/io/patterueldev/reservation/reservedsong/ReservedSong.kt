package io.patterueldev.reservation.reservedsong

interface ReservedSong {
    val id: String
    val songId: String
    val title: String
    val artist: String
    val imageURL: String
    val reservingUser: String
    val currentPlaying: Boolean
}
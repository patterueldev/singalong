package io.patterueldev.reservedsong

interface ReservedSong {
    val id: String
    var order: Int
    val songId: String
    val title: String
    val artist: String
    val thumbnailPath: String
    val reservingUser: String
    val currentPlaying: Boolean
    val completed: Boolean
}

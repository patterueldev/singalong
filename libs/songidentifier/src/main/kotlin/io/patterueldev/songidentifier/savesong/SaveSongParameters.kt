package io.patterueldev.songidentifier.savesong

import io.patterueldev.songidentifier.common.IdentifiedSong

data class SaveSongParameters(
    val song: IdentifiedSong,
    // user id; 'admin' if added by an admin
    val userId: String = "pat",
    // session id; 'admin' if added by an admin
    val sessionId: String = "admin",
    val thenReserve: Boolean,
)

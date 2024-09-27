package io.patterueldev.songidentifier.savesong

import io.patterueldev.songidentifier.common.IdentifiedSong

data class SaveSongParameters (
    val song: IdentifiedSong,
    val userId: String = "pat", // user id; 'admin' if added by an admin
    val sessionId: String = "admin", // session id; 'admin' if added by an admin
    val thenReserve: Boolean,
)
package io.patterueldev.songidentifier

import io.patterueldev.mongods.song.SongDocument
import io.patterueldev.songidentifier.common.SavedSong

fun SongDocument.toSavedSong(): SavedSong {
    return object : SavedSong {
        override val id: String = this@toSavedSong.id ?: throw Exception("Failed to save song")
        override val source: String = this@toSavedSong.source
        override val sourceId: String = this@toSavedSong.sourceId
        override val thumbnailPath: String = this@toSavedSong.thumbnailFile.path()
        override val videoPath: String? = this@toSavedSong.videoFile?.path()
        override val songTitle: String = this@toSavedSong.title
        override val songArtist: String = this@toSavedSong.artist
        override val songLanguage: String = this@toSavedSong.language
        override val isOffVocal: Boolean = this@toSavedSong.isOffVocal
        override val videoHasLyrics: Boolean = this@toSavedSong.videoHasLyrics
        override val songLyrics: String = this@toSavedSong.songLyrics
        override val lengthSeconds: Int = this@toSavedSong.lengthSeconds
    }
}

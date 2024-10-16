package io.patterueldev.songidentifier.common

data class IdentifiedSong(
    val id: String,
    val source: String,
    val imageUrl: String,
    val songTitle: String,
    val songArtist: String,
    val songLanguage: String,
    val isOffVocal: Boolean,
    val videoHasLyrics: Boolean,
    val songLyrics: String,
    val lengthSeconds: Int,
    val metadata: Map<String, Any>?,
) {
    fun copy(
        id: String? = this.id,
        source: String? = this.source,
        imageUrl: String? = this.imageUrl,
        songTitle: String? = this.songTitle,
        songArtist: String? = this.songArtist,
        songLanguage: String? = this.songLanguage,
        isOffVocal: Boolean? = this.isOffVocal,
        videoHasLyrics: Boolean? = this.videoHasLyrics,
        songLyrics: String? = this.songLyrics,
        lengthSeconds: Int? = this.lengthSeconds,
        metadata: Map<String, Any>? = this.metadata,
    ) = IdentifiedSong(
        id = id ?: this.id,
        source = source ?: this.source,
        imageUrl = imageUrl ?: this.imageUrl,
        songTitle = songTitle ?: this.songTitle,
        songArtist = songArtist ?: this.songArtist,
        songLanguage = songLanguage ?: this.songLanguage,
        isOffVocal = isOffVocal ?: this.isOffVocal,
        videoHasLyrics = videoHasLyrics ?: this.videoHasLyrics,
        songLyrics = songLyrics ?: this.songLyrics,
        lengthSeconds = lengthSeconds ?: this.lengthSeconds,
        metadata = metadata ?: this.metadata,
    )
}

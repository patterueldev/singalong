package io.patterueldev.songbook.deletesong

import io.patterueldev.common.GenericResponse
import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songbook.song.SongRecord
import io.patterueldev.songbook.song.SongRepository

internal class DeleteSongUseCase(
    private val songRepository: SongRepository,
) : ServiceUseCase<String, GenericResponse<SongRecord>> {
    override suspend fun execute(parameters: String): GenericResponse<SongRecord> {
        try {
            // first, get the song
            // if it doesn't exist, throw an exception

            val song =
                songRepository.getSongRecord(parameters)
                    ?: throw IllegalArgumentException("Song with id $parameters not found")

            // second, check if the song is reserved or playing
            // if it is, throw an exception
            val isPlayingOrAboutToPlay = songRepository.isPlayingOrAboutToPlay(parameters)
            if (isPlayingOrAboutToPlay) {
                throw IllegalArgumentException("Song is reserved or playing")
            }

            val wasReserved = songRepository.wasReserved(song.id)
            if (wasReserved) {
                println("Song was reserved: ${song.id}; will archive only")
                songRepository.archiveSong(songId = song.id)

                return GenericResponse.success(song, message = "Song was reserved, will archived only")
            }

            // next, check the sourceId if there's another song with the same sourceId
            // if there is, handle clean up; "merge" the songs
            // also check if those songs are reserved or playing
            // if they are, throw an exception
            val songsBySourceId = songRepository.getSongsBySourceId(song.sourceId)
            val otherSongs = songsBySourceId.filter { it.id != song.id }
            println("Other songs: ${otherSongs.size}")
            var canDeleteThumbnailFile = true
            var canDeleteVideoFile = true
            if (otherSongs.isNotEmpty()) {
                val reservedOrPlaying = otherSongs.any { songRepository.isPlayingOrAboutToPlay(it.id) }
                if (reservedOrPlaying) {
                    throw IllegalArgumentException("Other songs with the same sourceId are reserved or playing")
                }

                // check if the video files bucket object names are the same
                // like if the other song actually has the same object name, don't delete the video
                // otherwise, delete the video
                if (song.thumbnailFile.objectName.contains("default.jpg")) {
                    println("Will not delete thumbnail file, default.jpg")
                    canDeleteThumbnailFile = false
                } else {
                    val isThumbnailFileUsedByOtherSongs = otherSongs.any { it.thumbnailFile == song.thumbnailFile }
                    println("isThumbnailFileUsedByOtherSongs: $isThumbnailFileUsedByOtherSongs")
                    canDeleteThumbnailFile = !isThumbnailFileUsedByOtherSongs
                }

                val isVideoFileUsedByOtherSongs = otherSongs.any { it.videoFile == song.videoFile }
                println("isVideoFileUsedByOtherSongs: $isVideoFileUsedByOtherSongs")
                canDeleteVideoFile = !isVideoFileUsedByOtherSongs
            }

            println("Can Delete Thumbnail File: $canDeleteThumbnailFile")
            println("Can Delete Video File: $canDeleteVideoFile")

            // if there isn't, delete the song
            // delete associated files
            if (canDeleteThumbnailFile) songRepository.deleteSongFile(song.thumbnailFile)
            if (canDeleteVideoFile) songRepository.deleteSongFile(song.videoFile)

            println("Song was not reserved: ${song.id}; will delete")
            songRepository.deleteSong(songId = song.id)

            return GenericResponse.success(song)
        } catch (e: Exception) {
            println("Error: ${e.message}")
            return GenericResponse.failure(e.message ?: "An unknown error occurred while deleting song $parameters")
        }
    }
}

package io.patterueldev.reservation

import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.reservation.currentsong.CurrentSong
import io.patterueldev.reservation.currentsong.CurrentSongRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Repository
import kotlin.jvm.optionals.getOrNull

@Repository
open class CurrentSongRepositoryDS : CurrentSongRepository {
    @Autowired
    private lateinit var songDocumentRepository: SongDocumentRepository

    @Autowired
    private lateinit var reservedSongDocumentRepository: ReservedSongDocumentRepository

    private val mutex = Mutex()

    override suspend fun loadCurrentSong(roomId: String): CurrentSong? {
        mutex.withLock {
            println("Loading current song for room $roomId")
            // get the current song
            val currentReservedSong =
                withContext(Dispatchers.IO) {
                    reservedSongDocumentRepository.loadCurrentReservedSong(roomId)
                }
            if (currentReservedSong == null) {
                println("No current song")
                return null
            }

            println("Current song: $currentReservedSong")

            val song =
                withContext(Dispatchers.IO) {
                    songDocumentRepository.findById(currentReservedSong.songId)
                }.getOrNull() ?: throw IllegalArgumentException("Song not found")

            val videoPath = song.videoFile?.path() ?: throw IllegalArgumentException("Video file not found")

            return object : CurrentSong {
                override val id: String = currentReservedSong.id ?: throw IllegalArgumentException("Reserved song id not found")
                override val title: String = song.title
                override val artist: String = song.artist
                override val thumbnailPath: String = song.thumbnailFile.path()
                override val videoPath: String = videoPath
                override val durationInSeconds: Int = song.lengthSeconds
                override val reservingUser: String = currentReservedSong.reservedBy
            }
        }
    }
}

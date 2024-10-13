package io.patterueldev.reservation

import io.patterueldev.mongods.reservedsong.ReservedSongDocument
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.reservation.reservedsong.ReservedSong
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUser
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Repository
import kotlin.jvm.optionals.getOrNull

@Repository
open class ReservedSongRepositoryDS : ReservedSongsRepository {
    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    @Autowired private lateinit var reservedSongDocumentRepository: ReservedSongDocumentRepository

    private val mutex = Mutex()

    override suspend fun reserveSong(
        roomUser: RoomUser,
        songId: String,
    ) {
        mutex.withLock {
            // confirm existence of song
            val current =
                withContext(Dispatchers.IO) {
                    songDocumentRepository.findById(songId)
                }.getOrNull() ?: throw IllegalArgumentException("Song not found")

            // get the last order number
            val lastOrderNumber: Int =
                withContext(Dispatchers.IO) {
                    try {
                        reservedSongDocumentRepository.findMaxOrder(roomUser.roomId)
                    } catch (e: Exception) {
                        0
                    }
                }

            val reservedSong =
                ReservedSongDocument(
                    songId = songId,
                    roomId = roomUser.roomId,
                    order = lastOrderNumber + 1,
                    reservedBy = roomUser.username,
                )
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.save(reservedSong)
            }
        }
    }

    override suspend fun loadReservedSongs(roomId: String): List<ReservedSong> {
        val reservedSongs =
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.loadUnplayedReservedSongs(roomId)
            }
        val songIds = reservedSongs.map { it.songId }
        val songs =
            withContext(Dispatchers.IO) {
                songDocumentRepository.findAllById(songIds)
            }
        return reservedSongs.map { reservedSong ->
            val song =
                songs.find { song -> song.id == reservedSong.songId }
                    ?: throw IllegalArgumentException("Song with id ${reservedSong.songId} not found")
            object : ReservedSong {
                override val id: String = reservedSong.id ?: throw IllegalArgumentException("Reserved song id not found")
                override val order: Int = reservedSong.order
                override val songId: String = reservedSong.songId
                override val title: String = song.title
                override val artist: String = song.artist
                override val imageURL: String = song.imageUrl
                override val reservingUser: String = reservedSong.reservedBy
                override val currentPlaying: Boolean = reservedSong.startedPlayingAt != null && reservedSong.finishedPlayingAt == null
            }
        }
    }
}

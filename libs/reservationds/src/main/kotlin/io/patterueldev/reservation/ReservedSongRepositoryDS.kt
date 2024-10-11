package io.patterueldev.reservation

import io.patterueldev.mongods.reservedsong.ReservedSongDocument
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.reservation.reservedsong.ReservedSong
import io.patterueldev.reservation.reservedsong.ReservedSongsRepository
import io.patterueldev.roomuser.RoomUser
import kotlin.jvm.optionals.getOrNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.stereotype.Repository

@Repository
class ReservedSongRepositoryDS(
    val songDocumentRepository: SongDocumentRepository,
    val reservedSongDocumentRepository: ReservedSongDocumentRepository
) : ReservedSongsRepository {
    override suspend fun reserveSong(roomUser: RoomUser, songId: String) {
        // confirm existence of song
        val current = withContext(Dispatchers.IO) {
            songDocumentRepository.findById(songId)
        }.getOrNull() ?: throw IllegalArgumentException("Song not found")

        // get order number
        val lastOrderNumber = withContext(Dispatchers.IO) {
            reservedSongDocumentRepository.loadReservedSongs(roomUser.roomId)
        }.lastOrNull()?.order ?: 0

        val reservedSong = ReservedSongDocument(
            songId = songId,
            roomId = roomUser.roomId,
            order = lastOrderNumber,
            reservedBy = roomUser.username
        )
        return withContext(Dispatchers.IO) {
            reservedSongDocumentRepository.save(reservedSong)
        }
    }

    override suspend fun loadReservedSongs(roomId: String): List<ReservedSong> {
        val reservedSongs = withContext(Dispatchers.IO) {
            reservedSongDocumentRepository.loadReservedSongs(roomId)
        }
        val songIds = reservedSongs.map { it.songId }
        val songs = withContext(Dispatchers.IO) {
            songDocumentRepository.findAllById(songIds)
        }
        return reservedSongs.map { reservedSong ->
            val song = songs.find { song -> song.id == reservedSong.songId }
                ?: throw IllegalArgumentException("Song with id ${reservedSong.songId} not found")
            object : ReservedSong {
                override val id: String
                    get() = reservedSong.id ?: throw IllegalArgumentException("Reserved song id not found")
                override val songId: String
                    get() = reservedSong.songId
                override val title: String
                    get() = song.title
                override val artist: String
                    get() = song.artist
                override val imageURL: String
                    get() = song.imageUrl
                override val reservingUser: String
                    get() = reservedSong.reservedBy
                override val currentPlaying: Boolean
                    get() = reservedSong.finishedPlayingAt == null
            }
        }
    }
}
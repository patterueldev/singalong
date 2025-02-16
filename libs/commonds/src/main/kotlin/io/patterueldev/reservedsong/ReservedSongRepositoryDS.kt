package io.patterueldev.reservedsong

import io.minio.GetObjectArgs
import io.minio.MinioClient
import io.patterueldev.mongods.reservedsong.ReservedSongDocument
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.roomuser.RoomUser
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import kotlin.jvm.optionals.getOrNull

@Repository
open class ReservedSongRepositoryDS : ReservedSongsRepository {
    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    @Autowired private lateinit var reservedSongDocumentRepository: ReservedSongDocumentRepository

    @Autowired private lateinit var minioClient: MinioClient

    private val mutex = Mutex()

    override suspend fun reserveSong(
        roomUser: RoomUser,
        songId: String,
    ): ReservedSong {
        mutex.withLock {
            // confirm existence of song
            val song =
                withContext(Dispatchers.IO) {
                    songDocumentRepository.findById(songId)
                }.getOrNull() ?: throw IllegalArgumentException("Song not found")

            // check if song is not corrupted
            val videoFile = song.videoFile
            if (videoFile != null) {
                // validate if the video file exists
                withContext(Dispatchers.IO) {
                    try {
                        val video =
                            minioClient.getObject(
                                GetObjectArgs.builder()
                                    .bucket(videoFile.bucket)
                                    .`object`(videoFile.objectName)
                                    .build(),
                            )
                        println("Video file exists: $video")
                    } catch (e: Exception) {
                        println("Error checking video file: $e")
                        throw e
                    }
                }
            } else {
                println("Video File is null")
                throw Exception("Video file is null. Unable to reserve.")
            }

            // get the last order number
            val lastOrderNumber: Int =
                withContext(Dispatchers.IO) {
                    try {
                        reservedSongDocumentRepository.findMaxOrder(roomUser.roomId)
                    } catch (e: Exception) {
                        0
                    }
                }

            // check if there's a current song played
            val currentReservedSong =
                withContext(Dispatchers.IO) {
                    reservedSongDocumentRepository.loadCurrentReservedSong(roomUser.roomId)
                }
            val nothingIsPlaying = currentReservedSong == null

            val reservedSong =
                ReservedSongDocument(
                    songId = songId,
                    roomId = roomUser.roomId,
                    order = lastOrderNumber + 1,
                    reservedBy = roomUser.username,
                    startedPlayingAt = if (nothingIsPlaying) LocalDateTime.now() else null,
                )
            val newReservedSong =
                withContext(Dispatchers.IO) {
                    reservedSongDocumentRepository.save(reservedSong)
                }
            return object : ReservedSong {
                override val id: String = newReservedSong.id ?: throw IllegalArgumentException("Reserved song id not found")
                override var order: Int = newReservedSong.order
                override val songId: String = newReservedSong.songId
                override val title: String = song.title
                override val artist: String = song.artist
                override val thumbnailPath: String = song.thumbnailFile.path()
                override val reservingUser: String = newReservedSong.reservedBy
                override val currentPlaying: Boolean = newReservedSong.startedPlayingAt != null && newReservedSong.finishedPlayingAt == null
                override val completed: Boolean = newReservedSong.completed
            }
        }
    }

    private suspend fun loadReservedSongs(
        roomId: String,
        loadSongs: suspend (String) -> List<ReservedSongDocument>,
    ): List<ReservedSong> {
        val reservedSongs = withContext(Dispatchers.IO) { loadSongs(roomId) }
        println("Reserved songs: $reservedSongs")
        val songIds = reservedSongs.map { it.songId }
        val songs = withContext(Dispatchers.IO) { songDocumentRepository.findAllById(songIds) }
        return reservedSongs.map { reservedSong ->
            val song =
                songs.find { it.id == reservedSong.songId }
                    ?: throw IllegalArgumentException("Song with id ${reservedSong.songId} not found")
            object : ReservedSong {
                override val id: String = reservedSong.id ?: throw IllegalArgumentException("Reserved song id not found")
                override var order: Int = reservedSong.order
                override val songId: String = reservedSong.songId
                override val title: String = song.title
                override val artist: String = song.artist
                override val thumbnailPath: String = song.thumbnailFile.path()
                override val reservingUser: String = reservedSong.reservedBy
                override val currentPlaying: Boolean = reservedSong.startedPlayingAt != null && reservedSong.finishedPlayingAt == null
                override val completed: Boolean = reservedSong.completed
            }
        }
    }

    override suspend fun loadUnplayedReservedSongs(roomId: String): List<ReservedSong> {
        return loadReservedSongs(roomId) { reservedSongDocumentRepository.loadUnplayedReservedSongs(it) }
    }

    override suspend fun loadUnfinishedReservedSongs(roomId: String): List<ReservedSong> {
        return loadReservedSongs(roomId) { reservedSongDocumentRepository.loadUnfinishedReservedSongs(it) }
    }

    override suspend fun markFinishedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
        completed: Boolean,
    ) {
        // check if exists
        val reservedSong =
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.findById(reservedSongId)
            }.getOrNull() ?: throw IllegalArgumentException("Reserved song not found")
        reservedSongDocumentRepository.markFinishedPlaying(reservedSong.id!!, at, completed)
    }

    override suspend fun markStartedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
    ) {
        // check if exists
        val reservedSong =
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.findById(reservedSongId)
            }.getOrNull() ?: throw IllegalArgumentException("Reserved song not found")
        reservedSongDocumentRepository.markStartedPlaying(reservedSong.id!!, at)
    }

    override suspend fun getCountForFinishedSongsByUserInRoom(
        userId: String,
        roomId: String,
    ): Int {
        val result = reservedSongDocumentRepository.getCountForFinishedReservationsByUserInRoom(userId, roomId)
//        println("getCountForFinishedReservationsByUserInRoom(user: $userId, room: $roomId): $result")
        return result
    }

    override suspend fun getCountForUpcomingSongsByUserInRoom(
        userId: String,
        roomId: String,
    ): Int {
        return reservedSongDocumentRepository.getCountForUpcomingSongsByUserInRoom(userId, roomId)
    }

    override suspend fun cancelReservation(
        roomId: String,
        reservedSongId: String,
    ) {
        // check if exists
        val reservedSong =
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.findById(reservedSongId)
            }.getOrNull() ?: throw IllegalArgumentException("Reserved song not found")
        reservedSong.canceledAt = LocalDateTime.now()
        reservedSongDocumentRepository.save(reservedSong)
    }

    override suspend fun moveReservedSongOrder(
        roomId: String,
        reservedSongId: String,
        newOrder: Int,
    ) {
        val affectedReservedSong =
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.loadReservedSongFromRoom(roomId, reservedSongId)
            } ?: throw IllegalArgumentException("Reserved song not found")
        val oldOrder = affectedReservedSong.order
        if(oldOrder == newOrder) return // already in the same order

        val fromOrder = if (oldOrder > newOrder) newOrder else oldOrder
        val toOrder = if (oldOrder > newOrder) oldOrder else newOrder
        val affectedReservedSongs =
            withContext(Dispatchers.IO) {
                reservedSongDocumentRepository.loadReservedSongsBetweenOrders(roomId, fromOrder, toOrder)
            }

        if (affectedReservedSongs.size < 2) throw Exception("There are not enough reserved songs to move.")
        val isMovingUp = oldOrder > newOrder // by moving up, we mean the order is decreasing
        for (reservedSong in affectedReservedSongs) {
            reservedSong.oldOrder = reservedSong.order
            if (reservedSong.id == reservedSongId) {
                reservedSong.order = newOrder
                continue
            }
            reservedSong.order = if (isMovingUp) reservedSong.order + 1 else reservedSong.order - 1
        }
        reservedSongDocumentRepository.saveAll(affectedReservedSongs)
    }
}

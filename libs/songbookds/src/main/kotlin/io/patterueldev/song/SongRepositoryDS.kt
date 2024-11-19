package io.patterueldev.song

import io.minio.GetObjectArgs
import io.minio.MinioClient
import io.patterueldev.common.PaginatedData
import io.patterueldev.common.Pagination
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocument
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.songbook.UpdateSongParameters
import io.patterueldev.songbook.loadsongs.PaginatedSongs
import io.patterueldev.songbook.loadsongs.SongbookItem
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.SongDetails
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service

@Service
class SongRepositoryDS : SongRepository {
    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    @Autowired private lateinit var reservedSongDocumentRepository: ReservedSongDocumentRepository

    @Autowired private lateinit var minioClient: MinioClient

    override suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
        filteringIds: List<String>,
    ): PaginatedSongs {
        // only support PagePagination
        return try {
            // always paginate; and received page is based on 1-index
            // so if page is 0 or below, it's not a valid page; or do a minmax so if page is less than or equal to 0, it's 1
            var pageNumber = 1
            if (page != null) {
                when (page) {
                    is Pagination.PagePagination -> {
                        pageNumber = maxOf(1, page.pageNumber)
                    }
                    else -> {
                        throw IllegalArgumentException("Use `page` only for pagination")
                    }
                }
            }
            val pageable: Pageable = Pageable.ofSize(limit).withPage(pageNumber - 1)
            println("Filtering with IDs: ${filteringIds.joinToString(",")}")
            val pagedSongsResult: Page<SongDocument> =
                if (keyword.isNullOrBlank()) {
                    if (filteringIds.isEmpty()) {
                        songDocumentRepository.findAll(pageable)
                    } else {
                        songDocumentRepository.findAllNotInIds(filteringIds, pageable)
                    }
                } else {
                    if (filteringIds.isEmpty()) {
                        songDocumentRepository.findByKeyword(keyword, pageable)
                    } else {
                        songDocumentRepository.findByKeywordNotInIds(keyword, filteringIds, pageable)
                    }
                }
            val songs =
                pagedSongsResult.content.map {
                    SongbookItem(
                        id = it.id!!,
                        thumbnailPath = it.thumbnailFile.path(),
                        title = it.title,
                        artist = it.artist,
                        language = it.language,
                        isOffVocal = it.isOffVocal,
                        lengthSeconds = it.lengthSeconds,
                    )
                }
            val totalPages = pagedSongsResult.totalPages // e.g. 1
            val currentPage = pagedSongsResult.pageable.pageNumber // e.g. 0
            val nextPage = currentPage + 1 // e.g. 1
            if (nextPage >= totalPages) { // gt or eq is a bit excessive since ideally it should be eq; but doesn't hurt to be safe
                PaginatedData.lastPage(songs)
            } else {
                val nextPageBase1 = nextPage + 1
                PaginatedData.withNextPage(songs, nextPageBase1)
            }
        } catch (e: Exception) {
            println("Error loading songs: $e")
            println("Stacktrace: ${e.stackTraceToString()}")
            throw e
        }
    }

    override suspend fun loadReservedSongs(roomId: String): List<SongbookItem> {
        val reservedSongs = reservedSongDocumentRepository.loadAllByRoomId(roomId)
        println("Reserved songs found for room $roomId: ${reservedSongs.size}")
        val songIds = reservedSongs.map { it.songId }
        println("Attempting to load songs with IDs: ${songIds.joinToString(",")}")
        val songs = songDocumentRepository.findAllById(songIds)
        println("Songs found: ${songs.size}")
        return songs.map {
            SongbookItem(
                id = it.id!!,
                thumbnailPath = it.thumbnailFile.path(),
                title = it.title,
                artist = it.artist,
                language = it.language,
                isOffVocal = it.isOffVocal,
                lengthSeconds = it.lengthSeconds,
            )
        }
    }

    override suspend fun loadSongDetails(
        id: String,
        roomId: String?,
    ): SongDetails? {
        val song = songDocumentRepository.findByIdOrNull(id)
        return song?.let {
            var currentlyPlaying = false
            var wasReserved = false
            if (roomId != null) {
                val reservations = reservedSongDocumentRepository.loadReservationsByRoomIdAndSongId(roomId, it.id!!)
                wasReserved = reservations.isNotEmpty()
                currentlyPlaying = reservations.any { it.startedPlayingAt != null && it.finishedPlayingAt == null }
            }
            var isCorrupted = false
            val videoFile = song.videoFile
            if (videoFile != null) {
                // validate if the video file exists
                isCorrupted =
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
                            false
                        } catch (e: Exception) {
                            println("Error checking video file: $e")
                            true
                        }
                    }
            } else {
                println("Video File is null")
                isCorrupted = true
            }

            // check if the song data is corrupted e.g. video is missing, etc
            object : SongDetails {
                override val id: String = it.id!!
                override val source: String = it.source
                override val title: String = it.title
                override val artist: String = it.artist
                override val language: String = it.language
                override val isOffVocal: Boolean = it.isOffVocal
                override val videoHasLyrics: Boolean = it.videoHasLyrics
                override val duration: Int = it.lengthSeconds
                override val genres: List<String> = it.genres
                override val tags: List<String> = it.tags
                override val metadata: Map<String, String> = it.metadata
                override val thumbnailPath: String = it.thumbnailFile.path()
                override val wasReserved: Boolean = wasReserved
                override val currentPlaying: Boolean = currentlyPlaying
                override val lyrics: String = it.songLyrics
                override val addedBy: String = it.addedBy
                override val addedAtSession: String = it.addedAtSession
                override val lastUpdatedBy: String = it.lastModifiedBy
                override val isCorrupted: Boolean = isCorrupted
            }
        }
    }

    override suspend fun updateSongDetails(parameters: UpdateSongParameters): SongDetails {
        val songDocument =
            withContext(Dispatchers.IO) {
                songDocumentRepository.findById(parameters.songId)
            }.orElseThrow { Exception("Song not found") }

        val updatedSongDocument =
            songDocument.copy(
                title = parameters.title.trim(),
                artist = parameters.artist.trim(),
                language = parameters.language.trim(),
                isOffVocal = parameters.isOffVocal,
                videoHasLyrics = parameters.videoHasLyrics,
                songLyrics = parameters.songLyrics.trim(),
                metadata = parameters.metadata,
                genres = parameters.genres,
                tags = parameters.tags,
            )
        val updatedSong =
            withContext(Dispatchers.IO) {
                songDocumentRepository.save(updatedSongDocument)
            }
        return object : SongDetails {
            override val id: String = updatedSong.id!!
            override val source: String = updatedSong.source
            override val title: String = updatedSong.title
            override val artist: String = updatedSong.artist
            override val language: String = updatedSong.language
            override val isOffVocal: Boolean = updatedSong.isOffVocal
            override val videoHasLyrics: Boolean = updatedSong.videoHasLyrics
            override val duration: Int = updatedSong.lengthSeconds
            override val genres: List<String> = updatedSong.genres
            override val tags: List<String> = updatedSong.tags
            override val metadata: Map<String, String> = updatedSong.metadata
            override val thumbnailPath: String = updatedSong.thumbnailFile.path()
            override val wasReserved = false
            override val currentPlaying = false
            override val lyrics = updatedSong.songLyrics
            override val addedBy = updatedSong.addedBy
            override val addedAtSession = updatedSong.addedAtSession
            override val lastUpdatedBy = updatedSong.lastModifiedBy
            override val isCorrupted = false
        }
    }
}

package io.patterueldev.song

import io.minio.GetObjectArgs
import io.minio.MinioClient
import io.minio.RemoveObjectArgs
import io.patterueldev.common.BucketFile
import io.patterueldev.common.PaginatedData
import io.patterueldev.common.Pagination
import io.patterueldev.common.letOrElse
import io.patterueldev.identifysong.EnhancedSong
import io.patterueldev.identifysong.IdentifiedSong
import io.patterueldev.identifysong.IdentifySongParameters
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocument
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.roomuser.RoomUser
import io.patterueldev.songbook.loadsongs.PaginatedSongs
import io.patterueldev.songbook.loadsongs.SongbookItem
import io.patterueldev.songbook.song.SongRecord
import io.patterueldev.songbook.song.SongRepository
import io.patterueldev.songbook.songdetails.SongDetails
import io.patterueldev.songbook.updatesong.UpdateSongParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.web.reactive.function.client.WebClient
import java.time.LocalDateTime

@Service
class SongRepositoryDS(
    @Value("\${openai.token}") val openAIToken: String,
    @Value("\${openai.model}") val openAIModel: String,
) : SongRepository {
    @Autowired private lateinit var jsServiceWebClient: WebClient

    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    @Autowired private lateinit var reservedSongDocumentRepository: ReservedSongDocumentRepository

    @Autowired private lateinit var minioClient: MinioClient

    private val mutex = Mutex()

    override suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
        filteringIds: List<String>,
    ): PaginatedSongs {
        mutex.withLock {
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
                            songDocumentRepository.findAllUnarchived(pageable)
                        } else {
                            songDocumentRepository.findAllUnarchivedNotInIds(filteringIds, pageable)
                        }
                    } else {
                        songDocumentRepository.findUnarchivedByKeyword(keyword, pageable)
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
                val totalItems = pagedSongsResult.totalElements.toInt() // e.g. 1
                val nextPage = currentPage + 1 // e.g. 1
                if (nextPage >= totalPages) { // gt or eq is a bit excessive since ideally it should be eq; but doesn't hurt to be safe
                    PaginatedData.lastPage(songs, totalItems = totalItems, totalPages = totalPages)
                } else {
                    val nextPageBase1 = nextPage + 1
                    PaginatedData.withNextPage(songs, nextPageBase1, totalItems = totalItems, totalPages = totalPages)
                }
            } catch (e: Exception) {
                println("Error loading songs: $e")
                println("Stacktrace: ${e.stackTraceToString()}")
                throw e
            }
        }
    }

    override suspend fun loadReservedSongsInRoom(roomId: String): List<SongbookItem> {
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

    override suspend fun updateSongDetails(
        parameters: UpdateSongParameters,
        by: RoomUser,
    ): SongDetails {
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
                lastModifiedBy = by.username,
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

    override suspend fun isPlayingOrAboutToPlay(songId: String): Boolean {
        val reservations = reservedSongDocumentRepository.loadReservationsBySongId(songId)
        return reservations.any { it.startedPlayingAt != null && it.finishedPlayingAt == null }
    }

    override suspend fun wasReserved(songId: String): Boolean {
        return reservedSongDocumentRepository.loadReservationsBySongId(songId).isNotEmpty()
    }

    override suspend fun getSongRecord(songId: String): SongRecord? {
        val song = songDocumentRepository.findByIdOrNull(songId)
        return song?.let {
            object : SongRecord {
                override val id: String = it.id!!
                override val sourceId: String = it.sourceId
                override val thumbnailFile: BucketFile = it.thumbnailFile
                override val videoFile: BucketFile? = it.videoFile
            }
        }
    }

    override suspend fun getSongsBySourceId(sourceId: String): List<SongRecord> {
        val songs = songDocumentRepository.findAllBySourceId(sourceId)
        return songs.map {
            object : SongRecord {
                override val id: String = it.id!!
                override val sourceId: String = it.sourceId
                override val thumbnailFile: BucketFile = it.thumbnailFile
                override val videoFile: BucketFile? = it.videoFile
            }
        }
    }

    override suspend fun deleteSongFile(bucketFile: BucketFile?) {
        if (bucketFile != null) {
            withContext(Dispatchers.IO) {
                try {
                    minioClient.removeObject(
                        RemoveObjectArgs.builder()
                            .bucket(bucketFile.bucket)
                            .`object`(bucketFile.objectName)
                            .build(),
                    )
                } catch (e: Exception) {
                    println("Error deleting file: $e")
                }
            }
        }
    }

    override suspend fun deleteSong(songId: String) {
        val song = songDocumentRepository.findByIdOrNull(songId) ?: throw Exception("Song doesn't exist")
        withContext(Dispatchers.IO) {
            try {
                songDocumentRepository.deleteById(songId)
                println("Deleted song with ID $songId")
            } catch (e: Exception) {
                println("Error deleting song: $e")
                throw e
            }
        }
    }

    override suspend fun archiveSong(songId: String) {
        val song = songDocumentRepository.findByIdOrNull(songId) ?: throw Exception("Song doesn't exist")
        val updated = song.copy(archivedAt = LocalDateTime.now())
        withContext(Dispatchers.IO) {
            try {
                songDocumentRepository.save(updated)
                println("Archived song with ID $songId")
            } catch (e: Exception) {
                println("Error deleting song: $e")
            }
        }
    }

    override suspend fun enhanceSong(songId: String): SongDetails {
        val song = songDocumentRepository.findByIdOrNull(songId) ?: throw Exception("Song doesn't exist")
        val parameters = IdentifySongParameters(url = song.source)
        val identifiedSong =
            jsServiceWebClient.post()
                .uri("/identify")
                .bodyValue(parameters)
                .retrieve()
                .bodyToMono(IdentifiedSong::class.java)
                .block() ?: return loadSongDetails(songId, null) ?: throw Exception("No response from server")

        val enhancedSong =
            withContext(Dispatchers.IO) {
                jsServiceWebClient.post()
                    .uri("/enhance")
                    .header("openai-key", openAIToken)
                    .header("openai-model", openAIModel)
                    .bodyValue(identifiedSong)
                    .retrieve()
                    .bodyToMono(EnhancedSong::class.java)
                    .block()
            } ?: throw Exception("No response from server")

        val metadata: MutableMap<String, String> = mutableMapOf()
        enhancedSong.originalTitle.let {
            if (!it.isNullOrBlank()) {
                metadata["originalTitle"] = it
            }
        }

        enhancedSong.englishTitle.let {
            if (!it.isNullOrBlank()) {
                metadata["englishTitle"] = it
            }
        }

        return object : SongDetails {
            override val id: String = song.id!!
            override val source: String = song.source
            override val title: String = enhancedSong.romanizedTitle.letOrElse(identifiedSong.songTitle)
            override val artist: String = enhancedSong.artist.letOrElse(identifiedSong.songArtist)
            override val language: String = enhancedSong.language.letOrElse(identifiedSong.songLanguage)
            override val isOffVocal: Boolean = enhancedSong.isOffVocal.letOrElse(song.isOffVocal)
            override val videoHasLyrics: Boolean = enhancedSong.videoHasLyrics.letOrElse(song.videoHasLyrics)
            override val duration: Int = song.lengthSeconds
            override val genres: List<String> = enhancedSong.genres.letOrElse(song.genres)
            override val tags: List<String> = enhancedSong.relevantTags.letOrElse(song.tags)
            override val metadata: Map<String, String> = metadata
            override val thumbnailPath: String = song.thumbnailFile.path()
            override val wasReserved = false // TODO: Check if song was reserved
            override val currentPlaying = false
            override val lyrics = song.songLyrics
            override val addedBy = song.addedBy
            override val addedAtSession = song.addedAtSession
            override val lastUpdatedBy = song.lastModifiedBy
            override val isCorrupted = false
        }
    }
}

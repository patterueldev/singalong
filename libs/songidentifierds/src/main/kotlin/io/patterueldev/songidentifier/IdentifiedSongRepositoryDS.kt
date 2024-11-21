package io.patterueldev.songidentifier

import io.minio.MinioClient
import io.minio.PutObjectArgs
import io.patterueldev.common.BucketFile
import io.patterueldev.common.letOrElse
import io.patterueldev.identifysong.EnhancedSong
import io.patterueldev.identifysong.IdentifiedSong
import io.patterueldev.identifysong.IdentifySongParameters
import io.patterueldev.mongods.reservedsong.ReservedSongDocument
import io.patterueldev.mongods.reservedsong.ReservedSongDocumentRepository
import io.patterueldev.mongods.song.SongDocument
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.reservedsong.ReservedSong
import io.patterueldev.roomuser.RoomUser
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.SavedSong
import io.patterueldev.songidentifier.searchsong.SearchResultItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.reactive.function.client.WebClient
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.time.LocalDateTime
import kotlin.jvm.optionals.getOrNull

@Service
internal class IdentifiedSongRepositoryDS(
    @Value("\${openai.token}") val openAIToken: String,
    @Value("\${openai.model}") val openAIModel: String,
) : IdentifiedSongRepository {
    @Autowired private lateinit var jsServiceWebClient: WebClient

    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    @Autowired private lateinit var reservedSongDocumentRepository: ReservedSongDocumentRepository

    @Autowired private lateinit var minioClient: MinioClient

    private val mutex = Mutex()

    override suspend fun identifySong(url: String): IdentifiedSong? {
        return try {
            println("Fetching info for song at $url")
            val parameters = IdentifySongParameters(url = url)
            withContext(Dispatchers.IO) {
                jsServiceWebClient.post()
                    .uri("/identify")
                    .bodyValue(parameters)
                    .retrieve()
                    .bodyToMono(IdentifiedSong::class.java)
                    .block()
            }
        } catch (e: Exception) {
            println("Error occurred while attempting to identify: ${e.message}")
            null
        }
    }

    override suspend fun getExistingSong(identifiedSong: IdentifiedSong): IdentifiedSong? {
        try {
            val existing = songDocumentRepository.findBySourceId(identifiedSong.id) ?: return null
            return identifiedSong.copy(
                songTitle = existing.title,
                songArtist = existing.artist,
                songLanguage = existing.language,
                isOffVocal = existing.isOffVocal,
                videoHasLyrics = existing.videoHasLyrics,
                songLyrics = existing.songLyrics,
                lengthSeconds = existing.lengthSeconds,
                metadata = existing.metadata,
                alreadyExists = true,
            )
        } catch (e: Exception) {
            println("Error occurred while attempting to check for existence: ${e.message}")
            return null
        }
    }

    override suspend fun saveSong(
        identifiedSong: IdentifiedSong,
        userId: String,
        sessionId: String,
    ): SavedSong {
        println("Saving song to database")
        val bucket = "thumbnails"

        val song =
            SongDocument.new(
                source = identifiedSong.source,
                sourceId = identifiedSong.id,
                thumbnailFile = BucketFile.default(bucket),
                title = identifiedSong.songTitle,
                artist = identifiedSong.songArtist,
                language = identifiedSong.songLanguage,
                isOffVocal = identifiedSong.isOffVocal,
                videoHasLyrics = identifiedSong.videoHasLyrics,
                songLyrics = identifiedSong.songLyrics,
                lengthSeconds = identifiedSong.lengthSeconds,
                metadata = identifiedSong.metadata?.mapValues { it.value.toString() } ?: emptyMap(),
                genres = identifiedSong.genres,
                tags = identifiedSong.tags,
                addedBy = userId,
                addedAtSession = sessionId,
                lastModifiedBy = userId,
            )
        val saved =
            withContext(Dispatchers.IO) {
                songDocumentRepository.save(song)
            }
        return saved.toSavedSong()
    }

    override suspend fun downloadThumbnail(
        song: SavedSong,
        imageUrl: String,
        filename: String,
    ): SavedSong {
        var thumbnailFile: BucketFile? = null
        if (imageUrl.trim().isEmpty()) {
            return song
        }

        // download image and save to minio
        try {
            val bucket = "thumbnails"
            val objectName = "$filename.jpg"
            val result =
                withContext(Dispatchers.IO) {
                    val url = URI(imageUrl).toURL()
                    val bytes = url.readBytes()
                    println("Image bytes: ${bytes.size}")
                    // TODO: find a way to "extract" the file extension from the URL
                    minioClient.putObject(
                        PutObjectArgs.builder()
                            .bucket(bucket)
                            .`object`(objectName)
                            .stream(bytes.inputStream(), bytes.size.toLong(), -1)
                            .contentType("image/jpeg")
                            .build(),
                    )
                }
            // extract url
            thumbnailFile =
                BucketFile(
                    bucket = bucket,
                    objectName = objectName,
                )
            val current =
                withContext(Dispatchers.IO) {
                    songDocumentRepository.findById(song.id)
                }.orElseThrow { Exception("Song not found") }
            val updated = current.copy(thumbnailFile = thumbnailFile)
            withContext(Dispatchers.IO) {
                songDocumentRepository.save(updated)
            }
            return updated.toSavedSong()
        } catch (e: Exception) {
            println("Error while saving: ${e.message}")
            throw e
        }
    }

    override suspend fun downloadSong(
        song: SavedSong,
        sourceUrl: String,
        filename: String,
    ): SavedSong {
        try {
            val bucket = "videos"

            val parameters = DownloadSongParameters(url = sourceUrl)
            val bytes: ByteArray =
                withContext(Dispatchers.IO) {
                    jsServiceWebClient.post()
                        .uri("/download")
                        .bodyValue(parameters)
                        .retrieve()
                        .bodyToMono(ByteArray::class.java)
                        .block()
                } ?: throw Exception("No response from server")

            val objectName = "$filename.mp4"
            withContext(Dispatchers.IO) {
                println("Image bytes: ${bytes.size}")
                // TODO: find a way to "extract" the file extension from the URL
                minioClient.putObject(
                    PutObjectArgs.builder()
                        .bucket(bucket)
                        .`object`(objectName)
                        .stream(bytes.inputStream(), bytes.size.toLong(), -1)
                        .contentType("video/mp4")
                        .build(),
                )
            }

            val videoFile =
                BucketFile(
                    bucket = bucket,
                    objectName = objectName,
                )
            val current =
                withContext(Dispatchers.IO) {
                    songDocumentRepository.findById(song.id)
                }.orElseThrow { Exception("Song not found") }
            val updated = current.copy(videoFile = videoFile)
            withContext(Dispatchers.IO) {
                songDocumentRepository.save(updated)
            }
            return updated.toSavedSong()
        } catch (e: Exception) {
            println("Error while saving: ${e.message}")
            throw e
        }
    }

    override suspend fun updateSong(
        songId: String,
        filename: String,
    ): SavedSong {
        val song =
            withContext(Dispatchers.IO) {
                songDocumentRepository.findById(songId)
            }.orElseThrow { Exception("Song not found") }
        val updated = song.copy(filename = filename)
        withContext(Dispatchers.IO) {
            songDocumentRepository.save(updated)
        }
        return updated.toSavedSong()
    }

    override suspend fun reserveSong(
        roomUser: RoomUser,
        songId: String,
    ): ReservedSong {
        return mutex.withLock {
            // confirm existence of song
            val song =
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
            object : ReservedSong {
                override val id: String = newReservedSong.id ?: throw IllegalArgumentException("Reserved song id not found")
                override val order: Int = newReservedSong.order
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

    override suspend fun searchSongs(
        keyword: String,
        limit: Int,
    ): List<SearchResultItem> {
        return try {
            println("Searching for songs with keyword: $keyword")
            withContext(Dispatchers.IO) {
                val urlEncodedKeyword = URLEncoder.encode(keyword, StandardCharsets.UTF_8.toString())
                val urlQueries = mapOf("keyword" to urlEncodedKeyword, "limit" to limit.toString())
                val query = urlQueries.map { "${it.key}=${it.value}" }.joinToString("&")
                val urlPath = "/search?$query"
                jsServiceWebClient.get()
                    .uri(urlPath)
                    .retrieve()
                    .bodyToMono(Array<SearchResultItem>::class.java)
                    .block()
            }?.toList() ?: emptyList()
        } catch (e: Exception) {
            println("Error occurred while attempting to identify: ${e.message}")
            emptyList()
        }
    }

    override suspend fun enhanceSong(identifiedSong: IdentifiedSong): IdentifiedSong {
        return try {
            // js service /enhance, send header `openai-key`
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
            println("Enhancing song")

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

            val finalCopy =
                identifiedSong.copy(
                    songTitle = enhancedSong.romanizedTitle.letOrElse(identifiedSong.songTitle),
                    songArtist = enhancedSong.artist.letOrElse(identifiedSong.songArtist),
                    songLanguage = enhancedSong.language.letOrElse(identifiedSong.songLanguage),
                    isOffVocal = enhancedSong.isOffVocal.letOrElse(identifiedSong.isOffVocal),
                    videoHasLyrics = enhancedSong.videoHasLyrics.letOrElse(identifiedSong.videoHasLyrics),
                    genres = enhancedSong.genres.letOrElse(identifiedSong.genres),
                    tags = enhancedSong.relevantTags.letOrElse(identifiedSong.tags),
                    metadata = metadata,
                )

            println("Enhanced Identified Song: $finalCopy")

            finalCopy
        } catch (e: Exception) {
            println("Error while enhancing: ${e.message}")
            // Fallback
            identifiedSong
        }
    }
}

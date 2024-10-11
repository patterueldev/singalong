package io.patterueldev.songidentifier

import com.aallam.openai.api.chat.ChatCompletion
import com.aallam.openai.api.chat.ChatCompletionRequest
import com.aallam.openai.api.chat.ChatMessage
import com.aallam.openai.api.core.Role
import com.aallam.openai.api.model.ModelId
import com.aallam.openai.client.OpenAI
import io.patterueldev.mongods.song.SongDocument
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.songidentifier.common.IdentifiedSong
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.identifysong.IdentifySongParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import org.springframework.web.reactive.function.client.WebClient

@Service
internal class IdentifiedSongRepositoryDS : IdentifiedSongRepository {
    @Autowired private lateinit var songDownloaderClient: WebClient

    @Autowired private lateinit var openAIClient: OpenAI

    @Autowired private var openAIModel: ModelId? = null

    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    override suspend fun identifySong(url: String): IdentifiedSong? {
        return try {
            println("Fetching info for song at $url")
            val parameters = IdentifySongParameters(url = url)
            withContext(Dispatchers.IO) {
                songDownloaderClient.post()
                    .uri("/identify")
                    .bodyValue(parameters)
                    .retrieve()
                    .bodyToMono(IdentifiedSong::class.java)
                    .block()
            }
        } catch (e: Exception) {
            println("Error occurred while attempting to identify: ${e.message}")
            println("Error occurred while attempting to identify:")
            println(e.message)
            null
        }
    }

    override suspend fun enhanceSong(identifiedSong: IdentifiedSong): IdentifiedSong {
        return identifiedSong
        // my local AI can't handle this
        return try {
            // i wish there's a ping function; if there is, we can use it to check if the AI is up
            // if not, we can use a fallback

            // TODO: We'll be using AI to enhance the song
            // let's try identifying the artist
            println("Enhancing song using AI")
            val openAIModel = openAIModel ?: throw Exception("OpenAI model not found")
            val completionRequest =
                ChatCompletionRequest(
                    model = openAIModel,
                    messages =
                        listOf(
                            ChatMessage(
                                role = Role.System,
                                content = "Attempt to identify the artist; return 'Unidentified' if unable: ${identifiedSong.songTitle}",
                            ),
                        ),
                )
            val completion: ChatCompletion = openAIClient.chatCompletion(completionRequest)
            println("Successfully enhanced song using AI")
            identifiedSong.copy(
                songArtist = completion.choices[0].message.content,
            )
        } catch (e: Exception) {
            println("Error while enhancing: ${e.message}")
            // Fallback
            identifiedSong
        }
    }

    override suspend fun saveSong(
        identifiedSong: IdentifiedSong,
        userId: String,
        sessionId: String,
    ): String {
        println("Saving song to database")
        val song =
            SongDocument.new(
                source = identifiedSong.source,
                sourceId = identifiedSong.id,
                imageUrl = identifiedSong.imageUrl,
                title = identifiedSong.songTitle,
                artist = identifiedSong.songArtist,
                language = identifiedSong.songLanguage,
                isOffVocal = identifiedSong.isOffVocal,
                videoHasLyrics = identifiedSong.videoHasLyrics,
                songLyrics = identifiedSong.songLyrics,
                lengthSeconds = identifiedSong.lengthSeconds,
                metadata = identifiedSong.metadata?.mapValues { it.value.toString() } ?: emptyMap(),
                addedBy = userId,
                addedAtSession = sessionId,
                lastModifiedBy = sessionId,
            )
        val saved =
            withContext(Dispatchers.IO) {
                songDocumentRepository.save(song)
            }
        return saved.id ?: throw Exception("Failed to save song")
    }

    override suspend fun downloadSong(
        url: String,
        filename: String,
    ) {
        try {
            val parameters = DownloadSongParameters(url = url, filename = filename)
            val result =
                withContext(Dispatchers.IO) {
                    songDownloaderClient.post()
                        .uri("/download")
                        .bodyValue(parameters)
                        .retrieve()
                        .bodyToMono(DownloadSongResponse::class.java)
                        .block()
                } ?: throw Exception("No response from server")
            println("Download result: ${result.message}")
            if (result.success) {
                println("Download successful")
            } else {
                println("Download failed")
                throw Exception("Download failed")
            }
        } catch (e: Exception) {
            println("Error while saving: ${e.message}")
            throw e
        }
    }

    override suspend fun updateSong(
        songId: String,
        filename: String,
    ) {
        val song =
            withContext(Dispatchers.IO) {
                songDocumentRepository.findById(songId)
            }.orElseThrow { Exception("Song not found") }
        val updated = song.copy(filename = filename)
        withContext(Dispatchers.IO) {
            songDocumentRepository.save(updated)
        }
    }

    override suspend fun reserveSong(
        songId: String,
        sessionId: String,
    ) {
        println("Reserving song in database with ID: $songId to session: $sessionId")
        delay(1000)
    }
}

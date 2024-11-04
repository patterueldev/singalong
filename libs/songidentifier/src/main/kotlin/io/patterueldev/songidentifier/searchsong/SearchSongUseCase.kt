package io.patterueldev.songidentifier.searchsong

import io.patterueldev.common.ServiceUseCase
import io.patterueldev.songidentifier.common.IdentifiedSongRepository
import io.patterueldev.songidentifier.common.SearchSongResponse

internal open class SearchSongUseCase(
    private val identifiedSongRepository: IdentifiedSongRepository,
) : ServiceUseCase<String, SearchSongResponse> {
    override suspend fun execute(parameters: String): SearchSongResponse {
        try {
            // TODO: We can optimize results here
            if (parameters.isBlank()) {
                return SearchSongResponse.success(emptyList())
            }
            var keyword = parameters
            val keywords = listOf("lyrics", "off vocal", "instrumental", "カラオケ", "カラオケバージョン", "カラオケ音源", "カラオケ動画", "カラオケ配信", "karaoke")
            // if keyword doesn't contain any of the keywords, add "karaoke" to the keyword
            if (!keywords.any { keyword.contains(it, ignoreCase = true) }) {
                keyword += " karaoke"
            }
            val result = identifiedSongRepository.searchSongs(keyword)
            // TODO: Enhance response to identify also if the song is already saved
            return SearchSongResponse.success(result)
        } catch (e: Exception) {
            println("Error in SearchSongUseCase: ${e.message}")
            throw e
        }
    }
}

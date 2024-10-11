package io.patterueldev.song

import io.patterueldev.mongods.song.SongDocument
import io.patterueldev.mongods.song.SongDocumentRepository
import io.patterueldev.common.PaginatedData
import io.patterueldev.common.Pagination
import io.patterueldev.songbook.loadsongs.PaginatedSongs
import io.patterueldev.songbook.loadsongs.SongListItem
import io.patterueldev.songbook.song.SongRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service

@Service
class SongRepositoryDS : SongRepository {
    @Autowired private lateinit var songDocumentRepository: SongDocumentRepository

    override suspend fun loadSongs(
        limit: Int,
        keyword: String?,
        page: Pagination?,
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
            val pagedSongsResult: Page<SongDocument>
            if (keyword == null) {
                pagedSongsResult = songDocumentRepository.findAll(pageable)
            } else {
                pagedSongsResult =
                    withContext(Dispatchers.IO) {
                        songDocumentRepository.findByTitleAndArtist(
                            keyword, keyword, pageable,
                        )
                    }
            }
            val songs =
                pagedSongsResult.content.map {
                    SongListItem(
                        id = it.id!!,
                        imageUrl = it.imageUrl,
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
            throw e
        }
    }
}

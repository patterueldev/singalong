package io.patterueldev.songbook.loadsongs

import io.patterueldev.shared.PaginatedData

typealias PaginatedSongs = PaginatedData<SongListItem> // let's try this first

//data class PaginatedSongs (
//    val songs: List<Song>,
//    val totalPages: Int,
//    val nextOffset: Int?,
//    val nextCursor: String?,
//    val nextPage: Int?,
//) {
//    companion object {
//        fun empty(): PaginatedSongs {
//            return PaginatedSongs(emptyList(), 0, null, null, null)
//        }
//        fun lastPage(songs: List<Song>, totalPages: Int): PaginatedSongs {
//            return PaginatedSongs(songs, totalPages, null, null, null)
//        }
//        fun withNextOffset(songs: List<Song>, nextOffset: Int, totalPages: Int): PaginatedSongs {
//            return PaginatedSongs(songs, totalPages, nextOffset, null, null)
//        }
//        fun withNextCursor(songs: List<Song>, nextCursor: String, totalPages: Int): PaginatedSongs {
//            return PaginatedSongs(songs, totalPages, null, nextCursor, null)
//        }
//        fun withNextPage(songs: List<Song>, nextPage: Int, totalPages: Int): PaginatedSongs {
//            return PaginatedSongs(songs, totalPages, null, null, nextPage)
//        }
//    }
//}

package io.patterueldev.songidentifier.common

import io.patterueldev.common.GenericResponse
import io.patterueldev.identifysong.IdentifiedSong
import io.patterueldev.songidentifier.searchsong.SearchResultItem

typealias IdentifySongResponse = GenericResponse<IdentifiedSong>
typealias SaveSongResponse = GenericResponse<SavedSong>
typealias SearchSongResponse = GenericResponse<List<SearchResultItem>>

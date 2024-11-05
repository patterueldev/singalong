package io.patterueldev.songidentifier.searchsong

data class SearchResultItem(
    val type: String,
    val name: String,
    val id: String,
    val url: String,
    val thumbnail: String,
    val thumbnails: List<Thumbnail>,
    val isUpcoming: Boolean,
    val upcoming: Any?,
    val isLive: Boolean,
    val badges: List<String>,
    val author: Author,
    val description: String,
    val views: Int,
    val duration: String,
    val uploadedAt: String,
    val alreadyExists: Boolean = false,
)

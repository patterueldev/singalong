package io.patterueldev.songidentifier.searchsong

data class Author(
    val name: String,
    val channelID: String,
    val url: String,
    val bestAvatar: Avatar,
    val avatars: List<Avatar>,
    val ownerBadges: List<String>,
    val verified: Boolean,
)

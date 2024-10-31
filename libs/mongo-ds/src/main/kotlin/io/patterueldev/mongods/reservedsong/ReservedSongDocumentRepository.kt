package io.patterueldev.mongods.reservedsong

import java.time.LocalDateTime
import org.springframework.beans.factory.annotation.Value
import org.springframework.data.mongodb.repository.Aggregation
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.mongodb.repository.Update
import org.springframework.stereotype.Repository

@Repository
interface ReservedSongDocumentRepository : MongoRepository<ReservedSongDocument, String> {
    @Query(
        value = "{ 'roomId' : ?0, 'startedPlayingAt': null, 'finishedPlayingAt' : null }",
        sort = "{ 'order' : 1 }",
    )
    fun loadUnplayedReservedSongs(roomId: String): List<ReservedSongDocument>

    @Query(
        value = "{ 'roomId' : ?0, 'startedPlayingAt': { \$ne: null }, 'finishedPlayingAt' : null }",
    )
    fun loadCurrentReservedSong(roomId: String): ReservedSongDocument?

    @Aggregation(
        pipeline = [
            "{ \$match: { 'roomId' : ?0 } }",
            "{ \$group: { _id: '\$roomId', maxOrder: { \$max: '\$order' } } }",
        ],
    )
    fun findMaxOrder(roomId: String): Int

    @Query("{ '_id' : ?0 }")
    @Update("{ '\$set' : { 'finishedPlayingAt' : ?1 } }")
    fun markFinishedPlaying(reservedSongId: String, at: LocalDateTime)

    /*
    e.g.

    @Query("{ 'lastname' : ?0 }")
    @Update("{ '$inc' : { 'visits' : ?1 } }")

     */
    @Query("{ '_id' : ?0 }")
    @Update("{ '\$set' : { 'startedPlayingAt' : ?1 } }")
    fun markStartedPlaying(reservedSongId: String, at: LocalDateTime)
}
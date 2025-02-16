package io.patterueldev.mongods.reservedsong

import org.springframework.data.mongodb.repository.Aggregation
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.data.mongodb.repository.Update
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import org.springframework.data.mongodb.repository.CountQuery

@Repository
interface ReservedSongDocumentRepository : MongoRepository<ReservedSongDocument, String> {
    @Query(
        value = "{ 'roomId' : ?0, 'startedPlayingAt': null, 'finishedPlayingAt' : null, 'canceledAt' : null }",
        sort = "{ 'order' : 1 }",
    )
    fun loadUnplayedReservedSongs(roomId: String): List<ReservedSongDocument>

    @Query(
        value = "{ 'roomId' : ?0, 'id' : ?1 }",
    )
    fun loadReservedSongFromRoom(roomId: String, reservedSongId: String): ReservedSongDocument?

    @Query(
        value = "{ 'roomId' : ?0, 'order' : { \$gte: ?1, \$lte: ?2 } }",
        sort = "{ 'order' : 1 }",
    )
    fun loadReservedSongsBetweenOrders(
        roomId: String,
        fromOrder: Int,
        toOrder: Int,
    ): List<ReservedSongDocument>

    @Query(
        value = "{ 'roomId' : ?0, 'finishedPlayingAt' : null, 'canceledAt' : null }",
        sort = "{ 'order' : 1 }",
    )
    fun loadUnfinishedReservedSongs(roomId: String): List<ReservedSongDocument>

    @Query(
        value = "{ 'roomId' : ?0, 'startedPlayingAt': { \$ne: null }, 'finishedPlayingAt' : null, 'canceledAt' : null }",
    )
    fun loadCurrentReservedSong(roomId: String): ReservedSongDocument?

    @Query(
        value = "{ 'roomId' : ?0 }",
        sort = "{ 'order' : 1 }",
    )
    fun loadAllByRoomId(roomId: String): List<ReservedSongDocument>

    @Query(
        value = "{ 'roomId' : ?0, 'songId' : ?1 }",
    )
    fun loadReservationsByRoomIdAndSongId(roomId: String, songId: String): List<ReservedSongDocument>

    @Query(
        value = "{ 'songId' : ?0 }",
    )
    fun loadReservationsBySongId(songId: String): List<ReservedSongDocument>

    @Aggregation(
        pipeline = [
            "{ \$match: { 'roomId' : ?0 } }",
            "{ \$group: { _id: '\$roomId', maxOrder: { \$max: '\$order' } } }",
        ],
    )
    fun findMaxOrder(roomId: String): Int

    @Query("{ '_id' : ?0 }")
    @Update("{ '\$set' : { 'finishedPlayingAt' : ?1, 'completed' : ?2 } }")
    fun markFinishedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
        completed: Boolean,
    )

    @Query("{ '_id' : ?0 }")
    @Update("{ '\$set' : { 'startedPlayingAt' : ?1 } }")
    fun markStartedPlaying(
        reservedSongId: String,
        at: LocalDateTime,
    )

    @Query("{ '_id' : ?0 }")
    @Update("{ '\$set' : { 'canceledAt' : ?1 } }")
    fun markCanceledAt(
        reservedSongId: String,
        at: LocalDateTime,
    )

    @Query("{ '_id' : ?0 }")
    @Update("{ '\$set' : { 'order' : ?1 } }")
    fun updateOrderById(id: String, order: Int)

    @CountQuery(
        value = "{ 'roomId' : ?1, 'reservedBy' : ?0, 'completed' : true }",
    )
    fun getCountForFinishedReservationsByUserInRoom(userId: String, roomId: String): Int

    @CountQuery(
        value = "{ 'roomId' : ?1, 'reservedBy' : ?0, 'finishedPlayingAt' : null, 'canceledAt' : null }",
    )
    fun getCountForUpcomingSongsByUserInRoom(userId: String, roomId: String): Int
}

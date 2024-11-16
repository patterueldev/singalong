package io.patterueldev.singalong.api

import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.next.NextSongResponse
import io.patterueldev.reservation.reserve.ReserveParameters
import io.patterueldev.reservation.reserve.ReserveResponse
import io.patterueldev.songbook.SongBookService
import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songbook.loadsongs.LoadSongsResponse
import io.patterueldev.songidentifier.SongIdentifierService
import io.patterueldev.songidentifier.common.IdentifySongResponse
import io.patterueldev.songidentifier.common.SaveSongResponse
import io.patterueldev.songidentifier.common.SearchSongResponse
import io.patterueldev.songidentifier.identifysong.IdentifySongParameters
import io.patterueldev.songidentifier.savesong.SaveSongParameters
import io.patterueldev.songidentifier.searchsong.SearchSongParameters
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/songs")
class SongsController(
    private val songIdentifierService: SongIdentifierService,
    private val songBookService: SongBookService,
    private val reservationService: ReservationService,
) {
    @PostMapping("/identify")
    suspend fun identifySong(
        @RequestBody identifySongParameters: IdentifySongParameters,
    ): IdentifySongResponse = songIdentifierService.identifySong(identifySongParameters)

    @PostMapping
    suspend fun saveSong(
        @RequestBody saveSongParameters: SaveSongParameters,
    ): SaveSongResponse = songIdentifierService.saveSong(saveSongParameters)

    // Not to confuse, this is URL query parameters
    @GetMapping
    suspend fun loadSongs(
        @RequestParam keyword: String?,
        @RequestParam limit: Int = 20,
        @RequestParam nextOffset: Int?,
        @RequestParam nextCursor: String?,
        @RequestParam nextPage: Int?,
        @RequestParam roomId: String?,
    ): LoadSongsResponse =
        songBookService.loadSongs(
            LoadSongsParameters(
                keyword = keyword,
                limit = limit,
                offset = nextOffset,
                cursor = nextCursor,
                page = nextPage,
                roomId = roomId,
            ),
        )

    @PostMapping("/reserve")
    suspend fun reserveSong(
        @RequestBody reserveParameters: ReserveParameters,
    ): ReserveResponse = reservationService.reserveSong(reserveParameters)

    @GetMapping("/downloadable")
    suspend fun getDownloadableSongs(
        @RequestParam keyword: String,
        @RequestParam limit: Int = 20,
    ): SearchSongResponse =
        songIdentifierService.searchSong(
            SearchSongParameters(
                keyword = keyword,
                limit = limit,
            ),
        )

    @PatchMapping("/next")
    suspend fun nextSong(): NextSongResponse = reservationService.nextSong()
}

package io.patterueldev.singalong.api

import io.patterueldev.reservation.ReservationService
import io.patterueldev.reservation.list.LoadReservationListResponse
import io.patterueldev.reservation.reserve.ReserveParameters
import io.patterueldev.reservation.reserve.ReserveResponse
import io.patterueldev.songbook.SongBookService
import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songbook.loadsongs.LoadSongsResponse
import io.patterueldev.songidentifier.SongIdentifierService
import io.patterueldev.songidentifier.common.IdentifySongResponse
import io.patterueldev.songidentifier.common.SaveSongResponse
import io.patterueldev.songidentifier.identifysong.IdentifySongParameters
import io.patterueldev.songidentifier.savesong.SaveSongParameters
import org.springframework.web.bind.annotation.GetMapping
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
    ): LoadSongsResponse =
        songBookService.loadSongs(
            LoadSongsParameters(
                keyword = keyword,
                limit = limit,
                offset = nextOffset,
                cursor = nextCursor,
                page = nextPage,
            ),
        )

    @PostMapping("/reserve")
    suspend fun reserveSong(
        @RequestBody reserveParameters: ReserveParameters,
    ): ReserveResponse = reservationService.reserveSong(reserveParameters)
}

/*
Possible routes:

Song Identification:
- POST /songs/identify
Save Song:
- POST /songs ; body: {}
Song Details:
- GET /songs/{songId} ; body: {}
Song Book:
- GET /songs?keyword={keyword | null}&limit={limit | 20}&nextOffset={nextOffset | null}&nextCursor={nextCursor | null}&nextPage={nextPage | null} // only one of the next* should be used
Delete Song:
- DELETE /songs/{songId} // should not be lightly used

Sessions
Create new session
- POST /sessions ; {name: String} -> {sessionId}
End session
- DELETE /sessions/{sessionId}
Request connection to session (essentially like a registration/login)
- PATCH /sessions/{sessionId}/connect
Disconnect from session
- DELETE /sessions/{sessionId}/disconnect
Reserved Songs:
- GET /sessions/{sessionId}/reserved // maybe not used; because it's gonna be a websocket; but for REST testing
Reserve Song:
- POST /sessions/{sessionId}/reserved ; body: {songId}
Unreserve Song:
- DELETE /sessions/{sessionId}/reserved/{songId}
Rearrange Reserved Songs:
- PATCH /sessions/{sessionId}/reserved ; body: {songIds: [String]}
*/

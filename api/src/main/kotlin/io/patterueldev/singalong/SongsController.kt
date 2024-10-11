package io.patterueldev.singalong

import io.patterueldev.session.room.RoomUserDetails
import io.patterueldev.songbook.SongBookService
import io.patterueldev.songbook.loadsongs.LoadSongsParameters
import io.patterueldev.songidentifier.identifysong.IdentifySongParameters
import io.patterueldev.songidentifier.SongIdentifierService
import io.patterueldev.songidentifier.common.IdentifySongResponse
import io.patterueldev.songidentifier.savesong.SaveSongParameters
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/songs")
class SongsController(
    private val songIdentifierService: SongIdentifierService,
    private val songBookService: SongBookService
) {
    @PostMapping("/identify")
    suspend fun identifySong(
        @RequestBody identifySongParameters: IdentifySongParameters
    ): IdentifySongResponse {
        val authentication = SecurityContextHolder.getContext().authentication
        val userDetails = authentication.principal as RoomUserDetails

        val username = userDetails.username
        val roomId = userDetails.roomId
        val authorities = userDetails.authorities.joinToString { it.authority }

        println("Username: $username")
        println("Room ID: $roomId")
        println("Authorities: $authorities")

        val result = songIdentifierService.identifySong(identifySongParameters);
        println("Success Identified song: ${result.data?.songTitle}")
        return result
    }

    @PostMapping
    suspend fun saveSong(
        @RequestBody saveSongParameters: SaveSongParameters
    ) = songIdentifierService.saveSong(saveSongParameters)

    @GetMapping
    suspend fun loadSongs(
        @RequestParam keyword: String?,
        @RequestParam limit: Int = 20,
        @RequestParam nextOffset: Int?,
        @RequestParam nextCursor: String?,
        @RequestParam nextPage: Int?
    ) = songBookService.loadSongs(
        LoadSongsParameters(
            keyword = keyword,
            limit = limit,
            offset = nextOffset,
            cursor = nextCursor,
            page = nextPage
        )
    )
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
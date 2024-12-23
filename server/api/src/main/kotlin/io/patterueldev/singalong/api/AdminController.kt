package io.patterueldev.singalong.api

import io.patterueldev.admin.AdminService
import io.patterueldev.admin.assignplayertoroom.AssignPlayerToRoomParameters
import io.patterueldev.admin.connectwithroom.ConnectWithRoomParameters
import io.patterueldev.admin.room.LoadRoomListParameters
import io.patterueldev.room.createroom.CreateRoomParameters
import io.patterueldev.songbook.SongBookService
import io.patterueldev.songbook.enhancesong.EnhanceSongParameters
import io.patterueldev.songbook.songdetails.SongDetailsResponse
import io.patterueldev.songbook.updatesong.UpdateSongParameters
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/admin")
class AdminController(
    private val adminService: AdminService,
    private val songBookService: SongBookService,
) {
    @GetMapping("/rooms")
    suspend fun getRooms(
        @RequestParam keyword: String?,
        @RequestParam limit: Int = 20,
        @RequestParam nextOffset: Int?,
        @RequestParam nextCursor: String?,
        @RequestParam nextPage: Int?,
    ) = adminService.loadRoomList(
        LoadRoomListParameters(
            keyword = keyword,
            limit = limit,
            offset = nextOffset,
            cursor = nextCursor,
            page = nextPage,
        ),
    )

    @PostMapping("/rooms/connect")
    suspend fun connectWithRoom(
        @RequestBody connectWithRoomParameters: ConnectWithRoomParameters,
    ) = adminService.connectWithRoom(connectWithRoomParameters)

    @PostMapping("/rooms/assign")
    suspend fun assignPlayerToRoom(
        @RequestBody assignPlayerToRoomParameters: AssignPlayerToRoomParameters,
    ) = adminService.assignPlayerToRoom(assignPlayerToRoomParameters)

    @GetMapping("/rooms/generateid")
    suspend fun generateRoomId() = adminService.newRoomId()

    @PostMapping("/rooms/create")
    suspend fun createRoom(
        @RequestBody createRoomParameters: CreateRoomParameters,
    ) = adminService.createRoom(createRoomParameters)

    @PatchMapping("/song/update")
    suspend fun updateSongDetails(
        @RequestBody songDetails: UpdateSongParameters,
    ): SongDetailsResponse = songBookService.updateSong(songDetails)

    @DeleteMapping("/song/delete")
    suspend fun deleteSong(
        @RequestParam songId: String,
    ) = songBookService.deleteSong(songId)

    @PostMapping("/song/enhance")
    suspend fun enhanceSong(
        @RequestBody enhanceSongParameters: EnhanceSongParameters,
    ) = songBookService.enhanceSong(enhanceSongParameters)
}

package io.patterueldev.singalong.api

import io.patterueldev.admin.AdminService
import io.patterueldev.admin.connectwithroom.ConnectWithRoomParameters
import io.patterueldev.admin.room.LoadRoomListParameters
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/admin")
class AdminController(
    private val adminService: AdminService,
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
}

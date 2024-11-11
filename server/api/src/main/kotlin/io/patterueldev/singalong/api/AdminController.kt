package io.patterueldev.singalong.api

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/admin")
class AdminController {
    @GetMapping("/rooms")
    suspend fun getRooms() = "rooms"
}
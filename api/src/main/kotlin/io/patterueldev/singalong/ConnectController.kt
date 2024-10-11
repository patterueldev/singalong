package io.patterueldev.singalong

import SessionService
import io.patterueldev.session.connect.ConnectParameters
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController

@RestController
class ConnectController(
    private val sessionService: SessionService,
) {
    @PostMapping("/connect")
    suspend fun connect(
        @RequestBody connectParameters: ConnectParameters,
    ) = sessionService.connect(connectParameters)
}

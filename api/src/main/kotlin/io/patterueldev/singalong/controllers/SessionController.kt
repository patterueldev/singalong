package io.patterueldev.singalong.controllers

import io.patterueldev.session.SessionService
import io.patterueldev.session.connect.ConnectParameters
import io.patterueldev.session.setuserpasscode.SetUserPasscodeParameters
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/session")
class SessionController(
    private val sessionService: SessionService,
) {
    @PostMapping("/connect")
    suspend fun connect(
        @RequestBody connectParameters: ConnectParameters,
    ) = sessionService.connect(connectParameters)

    @PostMapping("/user/passcode")
    suspend fun setUserPasscode(
        @RequestBody setPasscodeParameters: SetUserPasscodeParameters,
    ) = sessionService.setUserPasscode(setPasscodeParameters)
}

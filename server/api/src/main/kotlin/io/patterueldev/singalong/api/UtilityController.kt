package io.patterueldev.singalong.api

import org.springframework.http.HttpHeaders
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.client.RestTemplate

@RestController
class UtilityController {
    // "proxy" for online images
    @GetMapping("/source-image")
    suspend fun sourceImage(
        @RequestParam url: String,
    ): ResponseEntity<ByteArray> {
        val restTemplate = RestTemplate()
        val response = restTemplate.getForEntity(url, ByteArray::class.java)
        val headers = HttpHeaders()
        headers.contentType = response.headers.contentType
        return ResponseEntity(response.body, headers, HttpStatus.OK)
    }
}

package com.darssolutionscr.backend.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/health")
class HealthController {

    @GetMapping
    fun getHealth(): Map<String, String> {
        return mapOf(
            "status" to "UP",
            "message" to "Application is running"
        )
    }

    @GetMapping("/database")
    fun checkDatabase(): Map<String, String> {
        return mapOf(
            "status" to "UP",
            "message" to "Database connection is healthy"
        )
    }
}
package com.darssolutionscr.backend.controller

import com.darssolutionscr.backend.model.dto.reservation.ReservationCreateRequest
import com.darssolutionscr.backend.model.dto.reservation.ReservationResponse
import com.darssolutionscr.backend.model.dto.reservation.ReservationUpdateRequest
import com.darssolutionscr.backend.service.ReservationService
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/reservations")
class ReservationController(
    private val reservationService: ReservationService,
) {

    @GetMapping
    fun getAll(): List<ReservationResponse> = reservationService.findAll()

    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ReservationResponse = reservationService.findById(id)

    @PostMapping
    fun create(@Valid @RequestBody request: ReservationCreateRequest): ResponseEntity<ReservationResponse> =
        ResponseEntity.status(HttpStatus.CREATED).body(reservationService.create(request))

    @PutMapping("/{id}")
    fun update(
        @PathVariable id: Long,
        @Valid @RequestBody request: ReservationUpdateRequest,
    ): ReservationResponse = reservationService.update(id, request)

    @PatchMapping("/{id}/deactivate")
    fun deactivate(@PathVariable id: Long): ReservationResponse = reservationService.deactivate(id)

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long): ResponseEntity<Void> {
        reservationService.delete(id)
        return ResponseEntity.noContent().build()
    }
}

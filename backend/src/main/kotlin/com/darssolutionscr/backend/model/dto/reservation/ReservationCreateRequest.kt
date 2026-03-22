package com.darssolutionscr.backend.model.dto.reservation

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.LocalDate
import java.time.LocalTime

data class ReservationCreateRequest(
    @field:NotBlank(message = "Customer name is required")
    @field:Size(max = 100, message = "Customer name must have at most 100 characters")
    val customerName: String,

    @field:NotNull(message = "Reservation date is required")
    val reservationDate: LocalDate,

    @field:NotNull(message = "Reservation time is required")
    val reservationTime: LocalTime,

    @field:NotBlank(message = "Service type is required")
    @field:Size(max = 100, message = "Service type must have at most 100 characters")
    val serviceType: String,
)

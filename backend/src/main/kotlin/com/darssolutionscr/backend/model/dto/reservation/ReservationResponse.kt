package com.darssolutionscr.backend.model.dto.reservation

import com.darssolutionscr.backend.model.entity.ReservationStatus
import java.time.LocalDate
import java.time.LocalTime

data class ReservationResponse(
    val id: Long,
    val customerName: String,
    val reservationDate: LocalDate,
    val reservationTime: LocalTime,
    val serviceType: String,
    val reservationType: ReservationStatus,
)

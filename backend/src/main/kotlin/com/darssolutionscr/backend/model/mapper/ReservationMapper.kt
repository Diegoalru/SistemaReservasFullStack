package com.darssolutionscr.backend.model.mapper

import com.darssolutionscr.backend.model.dto.reservation.ReservationCreateRequest
import com.darssolutionscr.backend.model.dto.reservation.ReservationResponse
import com.darssolutionscr.backend.model.dto.reservation.ReservationUpdateRequest
import com.darssolutionscr.backend.model.entity.Reservation
import com.darssolutionscr.backend.model.entity.ReservationStatus

fun ReservationCreateRequest.toEntity(reservationType: ReservationStatus): Reservation =
    Reservation(
        customerName = customerName,
        reservationDate = reservationDate,
        reservationTime = reservationTime,
        serviceType = serviceType,
        reservationType = reservationType,
    )

fun ReservationUpdateRequest.toEntity(id: Long, reservationType: ReservationStatus): Reservation =
    Reservation(
        id = id,
        customerName = customerName,
        reservationDate = reservationDate,
        reservationTime = reservationTime,
        serviceType = serviceType,
        reservationType = reservationType,
    )

fun Reservation.toResponse(): ReservationResponse {
    val reservationId = requireNotNull(id) { "Reservation id cannot be null when mapping to response" }
    return ReservationResponse(
        id = reservationId,
        customerName = customerName,
        reservationDate = reservationDate,
        reservationTime = reservationTime,
        serviceType = serviceType,
        reservationType = reservationType,
    )
}

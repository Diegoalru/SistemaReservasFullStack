package com.darssolutionscr.backend.service

import com.darssolutionscr.backend.model.dto.reservation.ReservationCreateRequest
import com.darssolutionscr.backend.model.dto.reservation.ReservationResponse
import com.darssolutionscr.backend.model.dto.reservation.ReservationUpdateRequest

interface ReservationService {
    fun findAll(): List<ReservationResponse>
    fun findById(id: Long): ReservationResponse
    fun create(request: ReservationCreateRequest): ReservationResponse
    fun update(id: Long, request: ReservationUpdateRequest): ReservationResponse
    fun deactivate(id: Long): ReservationResponse
    fun delete(id: Long)
}

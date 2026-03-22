package com.darssolutionscr.backend.repository

import com.darssolutionscr.backend.model.entity.Reservation
import com.darssolutionscr.backend.model.entity.ReservationStatus
import org.springframework.data.jpa.repository.JpaRepository
import java.time.LocalDate
import java.time.LocalTime

interface ReservationRepository : JpaRepository<Reservation, Long> {
    fun existsByReservationDateAndReservationTimeAndReservationType(
        date: LocalDate,
        time: LocalTime,
        reservationType: ReservationStatus,
    ): Boolean
}
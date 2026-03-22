package com.darssolutionscr.backend.service

import com.darssolutionscr.backend.exception.BusinessRuleException
import com.darssolutionscr.backend.exception.ResourceNotFoundException
import com.darssolutionscr.backend.model.dto.reservation.ReservationCreateRequest
import com.darssolutionscr.backend.model.dto.reservation.ReservationResponse
import com.darssolutionscr.backend.model.dto.reservation.ReservationUpdateRequest
import com.darssolutionscr.backend.model.entity.Reservation
import com.darssolutionscr.backend.model.entity.ReservationStatus
import com.darssolutionscr.backend.model.mapper.toEntity
import com.darssolutionscr.backend.model.mapper.toResponse
import com.darssolutionscr.backend.repository.ReservationRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class ReservationServiceImpl(
    private val reservationRepository: ReservationRepository,
) : ReservationService {

    @Transactional(readOnly = true)
    override fun findAll(): List<ReservationResponse> =
        reservationRepository.findAll().map { it.toResponse() }

    @Transactional(readOnly = true)
    override fun findById(id: Long): ReservationResponse =
        reservationRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("Reservation with id $id was not found") }
            .toResponse()

    @Transactional
    override fun create(request: ReservationCreateRequest): ReservationResponse {
        validateAvailableSlot(
            date = request.reservationDate,
            time = request.reservationTime,
            newStatus = ReservationStatus.ACTIVE,
        )
        return reservationRepository.save(request.toEntity(ReservationStatus.ACTIVE)).toResponse()
    }

    @Transactional
    override fun update(id: Long, request: ReservationUpdateRequest): ReservationResponse {
        val existingReservation = reservationRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("Reservation with id $id was not found") }

        validateAvailableSlot(
            date = request.reservationDate,
            time = request.reservationTime,
            newStatus = existingReservation.reservationType,
            existingReservation = existingReservation,
        )
        return reservationRepository.save(
            request.toEntity(
                id = id,
                reservationType = existingReservation.reservationType,
            )
        ).toResponse()
    }

    @Transactional
    override fun deactivate(id: Long): ReservationResponse {
        val existingReservation = reservationRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("Reservation with id $id was not found") }

        if (existingReservation.reservationType == ReservationStatus.CANCELLED) {
            return existingReservation.toResponse()
        }

        val cancelledReservation = existingReservation.copy(
            reservationType = ReservationStatus.CANCELLED,
        )

        return reservationRepository.save(cancelledReservation).toResponse()
    }

    @Transactional
    override fun delete(id: Long) {
        if (!reservationRepository.existsById(id)) {
            throw ResourceNotFoundException("Reservation with id $id was not found")
        }

        reservationRepository.deleteById(id)
    }

    private fun validateAvailableSlot(
        date: java.time.LocalDate,
        time: java.time.LocalTime,
        newStatus: ReservationStatus,
        existingReservation: Reservation? = null,
    ) {
        if (newStatus == ReservationStatus.CANCELLED) {
            return
        }

        if (
            existingReservation != null &&
            existingReservation.reservationDate == date &&
            existingReservation.reservationTime == time
        ) {
            return
        }

        val alreadyReserved =
            reservationRepository.existsByReservationDateAndReservationTimeAndReservationType(
                date,
                time,
                ReservationStatus.ACTIVE,
            )

        if (alreadyReserved) {
            throw BusinessRuleException("There is already a reservation for $date at $time")
        }
    }
}

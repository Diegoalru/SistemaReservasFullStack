package com.darssolutionscr.backend.model.entity

import jakarta.persistence.*
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.LocalDate
import java.time.LocalTime

@Entity
@Table(name = "reservations")
data class Reservation(
    @Id
    @Column(name = "reservation_id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false, length = 100, name = "reservation_customer_name")
    @field:NotBlank(message = "Customer name is required")
    @field:Size(max = 100, message = "Customer name must have at most 100 characters")
    val customerName: String,

    @Column(nullable = false, name = "reservation_customer_date")
    @field:NotNull(message = "Reservation date is required")
    val reservationDate: LocalDate,
    
    @Column(nullable = false, name = "reservation_customer_time")
    @field:NotNull(message = "Reservation time is required")
    val reservationTime: LocalTime,
    
    @Column(nullable = false, length = 100, name = "reservation_service_type")
    @field:NotBlank(message = "Service type is required")
    @field:Size(max = 100, message = "Service type must have at most 100 characters")
    val serviceType: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 100, name = "reservation_type")
    @field:NotNull(message = "Reservation status is required")
    val reservationType: ReservationStatus,
)
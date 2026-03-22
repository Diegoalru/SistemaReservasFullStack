package com.darssolutionscr.backend.exception

data class ApiErrorResponse(
    val status: Int,
    val error: String,
    val message: String,
    val details: List<String> = emptyList(),
)

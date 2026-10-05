package com.cbstudio.telltale.car.hardware

/**
 * Status of vehicle speed samples provided by the host platform (AA-05).
 */
enum class CarHostSpeedStatus {
    LIVE,
    STALE,
    UNAVAILABLE,
    UNIMPLEMENTED,
    PERMISSION_DENIED,
}

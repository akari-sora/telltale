package com.cbstudio.telltale.car.telemetry

/**
 * Why a projected signal does or does not carry a number.
 *
 * Only [LIVE] may carry a value. Every other status is a statement about the
 * absence of a presentable reading, and the three are kept apart because a car
 * UI must not say "this car lacks the sensor" ([UNSUPPORTED]) about a value
 * that merely went quiet ([STALE]) or never arrived ([UNAVAILABLE]).
 */
enum class CarSignalStatus {
    LIVE,
    STALE,
    UNSUPPORTED,
    UNAVAILABLE,
}

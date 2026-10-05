package com.cbstudio.telltale.car.hardware

/**
 * Immutable vehicle speed sample received from host CarInfo (AA-05).
 *
 * Invariants (AA05-07, AA05-08):
 * - Only STATUS_SUCCESS with finite float is LIVE.
 * - Non-LIVE samples MUST have null speeds (never fabricated 0).
 */
data class CarHostSpeedSample(
    val status: CarHostSpeedStatus,
    val rawMetersPerSecond: Float? = null,
    val displaySpeedMetersPerSecond: Float? = null,
    val sourceTimestampElapsedMs: Long? = null,
    val receivedAtElapsedMs: Long? = null,
) {
    companion object {
        val INITIAL = CarHostSpeedSample(
            status = CarHostSpeedStatus.UNAVAILABLE,
        )
    }
}

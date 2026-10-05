package com.cbstudio.telltale.car.hardware

import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlin.math.abs

/**
 * Vehicle motion evidence for driving safety and DTC gate (AA-05).
 */
enum class CarMotionEvidence {
    STATIONARY,
    MOVING,
    UNKNOWN,
}

/**
 * Conservative motion fusion resolver (AA05-15, AA05-16, AA05-17).
 *
 * Invariants:
 * - Any fresh source (OBD or Host raw/display) non-zero -> MOVING.
 *   Note: Host raw speed < 0 (reverse) is non-zero, hence MOVING (AA05-15).
 * - No fresh source says moving, and at least one fresh source is strictly 0 -> STATIONARY.
 * - No fresh speed evidence exists -> UNKNOWN.
 */
class CarVehicleMotionResolver {
    fun resolveMotion(
        telemetryState: CarTelemetryState,
        hostSpeedSample: CarHostSpeedSample,
    ): CarMotionEvidence {
        val freshSpeeds = mutableListOf<Double>()

        // 1. Check OBD speed
        val currentTelemetry = (telemetryState as? CarTelemetryState.Current)?.frame
        val obdSpeed = currentTelemetry?.speedKmh
        if (obdSpeed != null && obdSpeed.status == CarSignalStatus.LIVE) {
            val v = obdSpeed.value
            if (v != null && v.isFinite()) {
                freshSpeeds.add(v)
            }
        }

        // 2. Check Host speeds (both display and raw)
        if (hostSpeedSample.status == CarHostSpeedStatus.LIVE) {
            hostSpeedSample.displaySpeedMetersPerSecond?.let {
                if (it.isFinite()) freshSpeeds.add(it.toDouble())
            }
            hostSpeedSample.rawMetersPerSecond?.let {
                if (it.isFinite()) freshSpeeds.add(it.toDouble())
            }
        }

        if (freshSpeeds.isEmpty()) {
            return CarMotionEvidence.UNKNOWN
        }

        // AA05-16: Any fresh source non-zero -> MOVING (AA05-15: reverse < 0 is non-zero)
        if (freshSpeeds.any { it != 0.0 }) {
            return CarMotionEvidence.MOVING
        }

        // All available fresh sources are strictly zero
        return CarMotionEvidence.STATIONARY
    }
}

package com.cbstudio.telltale.car.safety

import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
import com.cbstudio.telltale.car.hardware.CarMotionEvidence
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarTelemetryState

enum class CarDtcMotionState {
    STATIONARY,
    MOVING,
    UNKNOWN,
}

/**
 * Motion gate protecting DTC inspection screens with conservative multi-source fusion (AA-04, AA-05).
 *
 * Invariants (AA05-15, AA05-16, AA05-17, AA05-18):
 * - Any fresh source non-zero (including reverse < 0) -> MOVING.
 * - All available fresh sources zero -> STATIONARY.
 * - No fresh evidence -> UNKNOWN.
 */
object CarDtcMotionGate {
    fun evaluate(
        state: CarTelemetryState,
        hostSpeedSample: CarHostSpeedSample = CarHostSpeedSample.INITIAL,
        motionResolver: CarVehicleMotionResolver = CarVehicleMotionResolver(),
    ): CarDtcMotionState {
        val motionEvidence = motionResolver.resolveMotion(state, hostSpeedSample)
        return when (motionEvidence) {
            CarMotionEvidence.MOVING -> CarDtcMotionState.MOVING
            CarMotionEvidence.STATIONARY -> {
                val current = state as? CarTelemetryState.Current
                if (current != null && current.frame.connectionPhase != CarConnectionPhase.CONNECTED) {
                    if (hostSpeedSample.status == CarHostSpeedStatus.LIVE &&
                        ((hostSpeedSample.displaySpeedMetersPerSecond ?: 1f) == 0f ||
                         (hostSpeedSample.rawMetersPerSecond ?: 1f) == 0f)) {
                        CarDtcMotionState.STATIONARY
                    } else {
                        CarDtcMotionState.UNKNOWN
                    }
                } else {
                    CarDtcMotionState.STATIONARY
                }
            }
            CarMotionEvidence.UNKNOWN -> CarDtcMotionState.UNKNOWN
        }
    }

    fun isStationary(
        state: CarTelemetryState,
        hostSpeedSample: CarHostSpeedSample = CarHostSpeedSample.INITIAL,
        motionResolver: CarVehicleMotionResolver = CarVehicleMotionResolver(),
    ): Boolean = evaluate(state, hostSpeedSample, motionResolver) == CarDtcMotionState.STATIONARY
}

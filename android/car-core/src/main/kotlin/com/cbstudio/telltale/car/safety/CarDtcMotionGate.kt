package com.cbstudio.telltale.car.safety

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryState

enum class CarDtcMotionState {
    STATIONARY,
    MOVING,
    UNKNOWN,
}

object CarDtcMotionGate {
    fun evaluate(state: CarTelemetryState): CarDtcMotionState {
        val current = state as? CarTelemetryState.Current ?: return CarDtcMotionState.UNKNOWN
        val frame = current.frame
        if (frame.connectionPhase != CarConnectionPhase.CONNECTED) {
            return CarDtcMotionState.UNKNOWN
        }

        val speed = frame.speedKmh
        if (speed.status != CarSignalStatus.LIVE) {
            return CarDtcMotionState.UNKNOWN
        }

        val speedVal = speed.value ?: return CarDtcMotionState.UNKNOWN
        if (!speedVal.isFinite()) return CarDtcMotionState.UNKNOWN

        return when {
            speedVal == 0.0 -> CarDtcMotionState.STATIONARY
            speedVal > 0.0 -> CarDtcMotionState.MOVING
            else -> CarDtcMotionState.UNKNOWN
        }
    }

    fun isStationary(state: CarTelemetryState): Boolean =
        evaluate(state) == CarDtcMotionState.STATIONARY
}

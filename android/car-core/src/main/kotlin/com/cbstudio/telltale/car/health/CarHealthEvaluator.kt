package com.cbstudio.telltale.car.health

import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarTelemetryState

enum class CarObservedHealth {
    NO_OBSERVED_WARNINGS,
    ATTENTION,
    UNKNOWN,
}

fun matchingDtcReport(telemetryState: CarTelemetryState, dtcState: CarDtcState): CarDtcReport? {
    val currentTelemetry = (telemetryState as? CarTelemetryState.Current)?.frame ?: return null
    val currentDtc = (dtcState as? CarDtcState.Current)?.report ?: return null
    if (currentTelemetry.connectionEpoch != currentDtc.connectionEpoch) return null
    return currentDtc
}

object CarHealthEvaluator {
    fun evaluate(
        telemetryState: CarTelemetryState,
        dtcState: CarDtcState,
        isAlertActive: Boolean = false,
    ): CarObservedHealth {
        // Priority 1: Attention (active warnings, MIL on, or detected DTCs)
        if (isAlertActive) return CarObservedHealth.ATTENTION

        val currentTelemetry = (telemetryState as? CarTelemetryState.Current)?.frame
        val currentDtc = matchingDtcReport(telemetryState, dtcState)

        val milOn = currentDtc?.milOn == true || currentTelemetry?.milOn == true
        if (milOn) return CarObservedHealth.ATTENTION

        val totalCodes = currentDtc?.totalCodes ?: currentTelemetry?.dtcCount
        if (totalCodes != null && totalCodes > 0L) {
            return CarObservedHealth.ATTENTION
        }
        if (currentDtc != null && currentDtc.items.isNotEmpty()) {
            return CarObservedHealth.ATTENTION
        }

        // Priority 2: NoObservedWarnings
        // Qualified only when:
        // - Telemetry is CURRENT and CONNECTED
        // - DTC report is CURRENT and matching connectionEpoch (guaranteed by currentDtc != null)
        // - DTC coverage is complete
        // - DTC verdict is COMPLETE_CLEAN
        // - MIL is explicitly false
        // - totalCodes is strictly 0L (not null)
        // - items is empty
        if (currentTelemetry != null &&
            currentTelemetry.connectionPhase == CarConnectionPhase.CONNECTED &&
            currentDtc != null &&
            currentDtc.coverageComplete &&
            currentDtc.verdict == CarDtcVerdict.COMPLETE_CLEAN &&
            currentDtc.milOn == false &&
            currentTelemetry.milOn != true &&
            currentDtc.totalCodes == 0L &&
            currentDtc.items.isEmpty()
        ) {
            return CarObservedHealth.NO_OBSERVED_WARNINGS
        }

        // Priority 3: Unknown (stale, partial, awaiting, unverified)
        return CarObservedHealth.UNKNOWN
    }
}


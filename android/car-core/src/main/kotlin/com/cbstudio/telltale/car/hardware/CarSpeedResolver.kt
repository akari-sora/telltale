package com.cbstudio.telltale.car.hardware

import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryState

/**
 * Origin of resolved vehicle speed (AA-05).
 */
enum class CarSpeedSource {
    OBD,
    HOST_DISPLAY,
    HOST_RAW,
}

/**
 * Resolved display speed with provenance metadata (AA-05).
 */
data class ResolvedDisplaySpeed(
    val status: CarSignalStatus,
    val speedKmh: Double? = null,
    val source: CarSpeedSource? = null,
)

/**
 * Vehicle speed resolver implementing prioritized arbitration without calibration (AA05-09 .. AA05-13).
 *
 * Arbitration Rules:
 * 1. OBD 010D LIVE -> OBD
 * 2. OBD unavailable/stale, CarInfo displaySpeed SUCCESS -> HOST_DISPLAY
 * 3. displaySpeed unavailable, but rawSpeed SUCCESS -> HOST_RAW
 * 4. No reliable data -> STALE (if prior state was known) or UNAVAILABLE. NEVER fabricates 0.
 */
class CarSpeedResolver {
    companion object {
        const val MPS_TO_KMH = 3.6
    }

    fun resolve(
        telemetryState: CarTelemetryState,
        hostSpeedSample: CarHostSpeedSample,
    ): ResolvedDisplaySpeed {
        val currentTelemetry = (telemetryState as? CarTelemetryState.Current)?.frame
        val obdSpeed = currentTelemetry?.speedKmh

        // Priority 1 (AA05-09): OBD 010D LIVE
        if (obdSpeed != null && obdSpeed.status == CarSignalStatus.LIVE) {
            val v = obdSpeed.value
            if (v != null && v.isFinite()) {
                return ResolvedDisplaySpeed(
                    status = CarSignalStatus.LIVE,
                    speedKmh = v,
                    source = CarSpeedSource.OBD,
                )
            }
        }

        // Priority 2 (AA05-10): OBD unavailable/stale, CarInfo displaySpeed SUCCESS / LIVE
        if (hostSpeedSample.status == CarHostSpeedStatus.LIVE) {
            val dispMps = hostSpeedSample.displaySpeedMetersPerSecond
            if (dispMps != null && dispMps.isFinite()) {
                val kmh = dispMps.toDouble() * MPS_TO_KMH
                return ResolvedDisplaySpeed(
                    status = CarSignalStatus.LIVE,
                    speedKmh = kmh,
                    source = CarSpeedSource.HOST_DISPLAY,
                )
            }

            // Priority 3 (AA05-11): displaySpeed unavailable, but rawSpeed SUCCESS / LIVE
            val rawMps = hostSpeedSample.rawMetersPerSecond
            if (rawMps != null && rawMps.isFinite()) {
                val kmh = rawMps.toDouble() * MPS_TO_KMH
                return ResolvedDisplaySpeed(
                    status = CarSignalStatus.LIVE,
                    speedKmh = kmh,
                    source = CarSpeedSource.HOST_RAW,
                )
            }
        }

        // Priority 4: Stale vs Unavailable (AA05-08: NEVER fabricate 0 km/h)
        val isStale = (telemetryState is CarTelemetryState.Stale && telemetryState.lastReceivedAtElapsedMs != null) ||
                (obdSpeed != null && obdSpeed.status == CarSignalStatus.STALE) ||
                hostSpeedSample.status == CarHostSpeedStatus.STALE

        return if (isStale) {
            ResolvedDisplaySpeed(status = CarSignalStatus.STALE, speedKmh = null, source = null)
        } else {
            ResolvedDisplaySpeed(status = CarSignalStatus.UNAVAILABLE, speedKmh = null, source = null)
        }
    }
}

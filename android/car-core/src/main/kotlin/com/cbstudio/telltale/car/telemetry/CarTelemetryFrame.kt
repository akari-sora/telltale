package com.cbstudio.telltale.car.telemetry

/** Mirror of the phone app's connection phase, as carried by schema v1. */
enum class CarConnectionPhase {
    DISCONNECTED,
    CONNECTING,
    HANDSHAKING,
    CONNECTED,
    FAILED,
}

/** A signal exactly as it came off the transport, before validation. */
data class CarSignalInput(
    val status: CarSignalStatus,
    val value: Double?,
)

/**
 * A decoded but *unvalidated* frame.
 *
 * Only [CarTelemetryRepository.submit] turns this into a [CarTelemetryFrame].
 * Nothing in the car UI may read this type.
 */
data class CarTelemetryFrameInput(
    val schemaVersion: Long,
    val sequence: Long,
    val connectionEpoch: Long,
    val lifecycleEpoch: Long,
    val producedAtMonotonicUs: Long,
    val connectionPhase: CarConnectionPhase,
    val speedKmh: CarSignalInput,
    val rpm: CarSignalInput,
    val coolantC: CarSignalInput,
    val intakeAirC: CarSignalInput,
    val controlModuleVoltageV: CarSignalInput,
    val mapKpa: CarSignalInput,
    val diagnosticsAvailable: Boolean,
    val milOn: Boolean?,
    val dtcCount: Long?,
)

/**
 * A validated schema-v1 frame. Every signal has passed the transport envelope
 * and obeys the live-iff-numeric invariant of [CarSignalValue].
 *
 * `producedAtMonotonicUs` is producer-side time. It is evidence for ordering
 * and latency inside one producer only; host freshness never uses it.
 */
data class CarTelemetryFrame(
    val schemaVersion: Long,
    val sequence: Long,
    val connectionEpoch: Long,
    val lifecycleEpoch: Long,
    val producedAtMonotonicUs: Long,
    val connectionPhase: CarConnectionPhase,
    val speedKmh: CarSignalValue,
    val rpm: CarSignalValue,
    val coolantC: CarSignalValue,
    val intakeAirC: CarSignalValue,
    val controlModuleVoltageV: CarSignalValue,
    val mapKpa: CarSignalValue,
    val diagnosticsAvailable: Boolean,
    val milOn: Boolean?,
    val dtcCount: Long?,
) {
    companion object {
        /** The only schema version this host understands. */
        const val SCHEMA_VERSION: Long = 1

        // Transport-corruption envelopes. Deliberately wider than any healthy
        // vehicle: they reject garbage, not unusual-but-real readings.
        val SPEED_KMH_ENVELOPE = 0.0..400.0
        val RPM_ENVELOPE = 0.0..20_000.0
        val COOLANT_C_ENVELOPE = -80.0..300.0
        val INTAKE_AIR_C_ENVELOPE = -80.0..300.0
        val CONTROL_MODULE_VOLTAGE_V_ENVELOPE = 0.0..60.0
        val MAP_KPA_ENVELOPE = 0.0..500.0
        val DTC_COUNT_RANGE = 0L..65_535L
    }
}

package com.cbstudio.telltale.car.telemetry

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** Outcome of one [CarTelemetryRepository.submit], for evidence and tests. */
enum class CarTelemetrySubmitResult {
    ACCEPTED,
    INCOMPATIBLE_SCHEMA,
    DROPPED_MALFORMED_HEADER,
    DROPPED_OLD_CONNECTION_EPOCH,
    DROPPED_OUT_OF_ORDER_SEQUENCE,
    DROPPED_LIFECYCLE_REGRESSION,
}

/**
 * The single host-side authority for projected phone telemetry.
 *
 * Read-only from the car's point of view: it accepts frames from exactly one
 * direction (the Flutter producer) and exposes [state]. There is no path from
 * here back to the producer.
 *
 * Contract (AA-02):
 * - schemaVersion != 1 → [CarTelemetryState.Incompatible]; no numbers.
 * - A malformed header, an older connection epoch, a non-increasing sequence
 *   within one connection epoch, or a lifecycle epoch going backwards within
 *   one connection epoch is dropped and does not change state.
 * - A newer connection epoch starts a fresh sequence domain.
 * - Each signal is sanitized independently; one bad signal never rejects the
 *   frame.
 * - [staleAfterMs] without a valid *accepted* frame → [CarTelemetryState.Stale].
 *   Rejected frames never refresh that deadline.
 * - Freshness uses only this host's own monotonic clock ([elapsedRealtimeMs]);
 *   the producer's timestamp is never subtracted from it.
 *
 * Thread-safe: submissions arrive on the platform thread while the stale timer
 * runs on [scope]; all transitions happen under one lock and the timer only
 * acts if no newer frame was accepted since it was armed.
 */
class CarTelemetryRepository(
    private val scope: CoroutineScope,
    private val elapsedRealtimeMs: () -> Long,
    private val staleAfterMs: Long = DEFAULT_STALE_AFTER_MS,
    private val dtcRepository: com.cbstudio.telltale.car.diagnostics.CarDtcRepository? = null,
) {
    private val lock = Any()
    private val mutableState = MutableStateFlow<CarTelemetryState>(CarTelemetryState.Awaiting)

    val state: StateFlow<CarTelemetryState> = mutableState.asStateFlow()

    private var lastConnectionEpoch: Long? = null
    private var lastSequence: Long? = null
    private var lastLifecycleEpoch: Long? = null
    private var lastReceivedAtElapsedMs: Long? = null
    private var staleJob: Job? = null

    /** Increments on every accept/reset so an armed timer can tell it is outdated. */
    private var acceptGeneration: Long = 0

    /**
     * A (new) producer is attached, e.g. a FlutterEngine (re)registered the
     * host API. Its sequence numbers restart, so ordering restarts with it.
     */
    fun onProducerAttached() {
        synchronized(lock) {
            acceptGeneration++
            staleJob?.cancel()
            staleJob = null
            lastConnectionEpoch = null
            lastSequence = null
            lastLifecycleEpoch = null
            lastReceivedAtElapsedMs = null
            mutableState.value = CarTelemetryState.Awaiting
            (dtcRepository ?: com.cbstudio.telltale.car.diagnostics.CarDtcRuntime.repository).reset()
        }
    }

    /** Never throws: a bad frame is a dropped frame, not a producer error. */
    fun submit(input: CarTelemetryFrameInput): CarTelemetrySubmitResult {
        synchronized(lock) {
            if (input.schemaVersion != CarTelemetryFrame.SCHEMA_VERSION) {
                acceptGeneration++
                staleJob?.cancel()
                staleJob = null
                mutableState.value = CarTelemetryState.Incompatible(input.schemaVersion)
                return CarTelemetrySubmitResult.INCOMPATIBLE_SCHEMA
            }
            if (input.sequence < 0 ||
                input.connectionEpoch < 0 ||
                input.lifecycleEpoch < 0 ||
                input.producedAtMonotonicUs < 0
            ) {
                return CarTelemetrySubmitResult.DROPPED_MALFORMED_HEADER
            }

            val previousEpoch = lastConnectionEpoch
            if (previousEpoch != null) {
                if (input.connectionEpoch < previousEpoch) {
                    return CarTelemetrySubmitResult.DROPPED_OLD_CONNECTION_EPOCH
                }
                if (input.connectionEpoch == previousEpoch) {
                    val previousSequence = lastSequence
                    if (previousSequence != null && input.sequence <= previousSequence) {
                        return CarTelemetrySubmitResult.DROPPED_OUT_OF_ORDER_SEQUENCE
                    }
                    val previousLifecycle = lastLifecycleEpoch
                    if (previousLifecycle != null && input.lifecycleEpoch < previousLifecycle) {
                        return CarTelemetrySubmitResult.DROPPED_LIFECYCLE_REGRESSION
                    }
                }
            }

            val frame = validate(input)
            val now = elapsedRealtimeMs()
            lastConnectionEpoch = input.connectionEpoch
            lastSequence = input.sequence
            lastLifecycleEpoch = input.lifecycleEpoch
            lastReceivedAtElapsedMs = now
            mutableState.value = CarTelemetryState.Current(frame, now)
            armStaleTimer()
            return CarTelemetrySubmitResult.ACCEPTED
        }
    }

    private fun armStaleTimer() {
        val generation = ++acceptGeneration
        staleJob?.cancel()
        staleJob =
            scope.launch {
                delay(staleAfterMs)
                expireIfStill(generation)
            }
    }

    private fun expireIfStill(generation: Long) {
        synchronized(lock) {
            if (generation != acceptGeneration) return
            if (mutableState.value !is CarTelemetryState.Current) return
            staleJob = null
            mutableState.value =
                CarTelemetryState.Stale(
                    connectionEpoch = lastConnectionEpoch,
                    lastReceivedAtElapsedMs = lastReceivedAtElapsedMs,
                )
        }
    }

    companion object {
        /** About six missed frames at the producer's 2 Hz ceiling. */
        const val DEFAULT_STALE_AFTER_MS: Long = 3_000

        internal fun validate(input: CarTelemetryFrameInput): CarTelemetryFrame {
            val diagnostics = input.diagnosticsAvailable
            val dtcCount =
                input.dtcCount?.takeIf { diagnostics && it in CarTelemetryFrame.DTC_COUNT_RANGE }
            return CarTelemetryFrame(
                schemaVersion = input.schemaVersion,
                sequence = input.sequence,
                connectionEpoch = input.connectionEpoch,
                lifecycleEpoch = input.lifecycleEpoch,
                producedAtMonotonicUs = input.producedAtMonotonicUs,
                connectionPhase = input.connectionPhase,
                speedKmh = input.speedKmh.sanitize(CarTelemetryFrame.SPEED_KMH_ENVELOPE),
                rpm = input.rpm.sanitize(CarTelemetryFrame.RPM_ENVELOPE),
                coolantC = input.coolantC.sanitize(CarTelemetryFrame.COOLANT_C_ENVELOPE),
                intakeAirC = input.intakeAirC.sanitize(CarTelemetryFrame.INTAKE_AIR_C_ENVELOPE),
                controlModuleVoltageV =
                    input.controlModuleVoltageV.sanitize(
                        CarTelemetryFrame.CONTROL_MODULE_VOLTAGE_V_ENVELOPE,
                    ),
                mapKpa = input.mapKpa.sanitize(CarTelemetryFrame.MAP_KPA_ENVELOPE),
                diagnosticsAvailable = diagnostics,
                // Unknown MIL stays unknown; it is never turned into "off".
                milOn = if (diagnostics) input.milOn else null,
                dtcCount = dtcCount,
            )
        }

        private fun CarSignalInput.sanitize(envelope: ClosedFloatingPointRange<Double>): CarSignalValue =
            CarSignalValue.sanitize(status, value, envelope)
    }
}

package com.cbstudio.telltale.car.telemetry

/**
 * What the car side may currently believe about phone telemetry.
 *
 * Only [Current] carries presentable values. [Stale] and [Incompatible]
 * intentionally carry no frame, so a UI cannot render an old or undecodable
 * number as if it were live.
 */
sealed interface CarTelemetryState {
    /** No producer frame accepted since the producer (re)attached. */
    data object Awaiting : CarTelemetryState

    data class Current(
        val frame: CarTelemetryFrame,
        /** Host monotonic receive time (elapsedRealtime domain). */
        val receivedAtElapsedMs: Long,
    ) : CarTelemetryState

    /** No valid accepted frame within the staleness window. */
    data class Stale(
        val connectionEpoch: Long?,
        val lastReceivedAtElapsedMs: Long?,
    ) : CarTelemetryState

    /** The producer speaks a schema this host does not understand. */
    data class Incompatible(
        val receivedSchemaVersion: Long,
    ) : CarTelemetryState
}

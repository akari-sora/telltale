package com.cbstudio.telltale.car.health

import com.cbstudio.telltale.car.telemetry.CarTelemetryState

/**
 * Immutable snapshot of vehicle alert state evaluated at session scope (AA-05).
 */
data class CarAlertSnapshot(
    val level: CarAlertLevel,
    val coolant: CarAlertPhase,
    val connectionEpoch: Long?,
) {
    companion object {
        val INITIAL = CarAlertSnapshot(
            level = CarAlertLevel.NORMAL,
            coolant = CarAlertPhase.NORMAL,
            connectionEpoch = null,
        )
    }
}

/**
 * Transition between two [CarAlertSnapshot] instances across an edge.
 */
data class CarAlertTransition(
    val previous: CarAlertSnapshot,
    val current: CarAlertSnapshot,
)

/**
 * Identifies semantic state transitions that require immediate UI invalidation (AA05-30).
 */
fun isSemanticAlertEdge(oldPhase: CarAlertPhase, newPhase: CarAlertPhase): Boolean {
    if (oldPhase == newPhase) return false
    return (oldPhase == CarAlertPhase.NORMAL && newPhase == CarAlertPhase.ACTIVE) ||
            (oldPhase == CarAlertPhase.PENDING_ENTER && newPhase == CarAlertPhase.ACTIVE) ||
            (oldPhase == CarAlertPhase.PENDING_CLEAR && newPhase == CarAlertPhase.ACTIVE) ||
            (oldPhase == CarAlertPhase.UNKNOWN_AFTER_WARNING && newPhase == CarAlertPhase.ACTIVE) ||
            (oldPhase == CarAlertPhase.ACTIVE && newPhase == CarAlertPhase.UNKNOWN_AFTER_WARNING) ||
            (oldPhase == CarAlertPhase.ACTIVE && newPhase == CarAlertPhase.NORMAL) ||
            (oldPhase == CarAlertPhase.PENDING_CLEAR && newPhase == CarAlertPhase.NORMAL) ||
            (oldPhase == CarAlertPhase.UNKNOWN_AFTER_WARNING && newPhase == CarAlertPhase.NORMAL)
}

/**
 * Resolves a [CarAlertSnapshot] only if it strictly matches the current or stale telemetry connection's [connectionEpoch].
 * Prevents alert state from previous vehicle sessions or connections leaking into a newly connected vehicle (AA05 Blocker 3).
 */
fun matchingAlertSnapshot(
    telemetryState: CarTelemetryState,
    alertSnapshot: CarAlertSnapshot,
): CarAlertSnapshot? {
    val frameEpoch = when (telemetryState) {
        is CarTelemetryState.Current -> telemetryState.frame.connectionEpoch
        is CarTelemetryState.Stale -> telemetryState.connectionEpoch
        is CarTelemetryState.Awaiting, is CarTelemetryState.Incompatible -> null
    } ?: return null
    if (alertSnapshot.connectionEpoch != frameEpoch) {
        return null
    }
    return alertSnapshot
}

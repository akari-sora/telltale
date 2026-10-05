package com.cbstudio.telltale.car.health

enum class CarAlertLevel {
    NORMAL,
    ATTENTION,
    UNKNOWN,
}

enum class CarAlertPhase {
    NORMAL,
    PENDING_ENTER,
    ACTIVE,
    PENDING_CLEAR,
    UNKNOWN_AFTER_WARNING,
}

data class CarAlertPolicy(
    val enterThreshold: Double,
    val enterHoldMs: Long,
    val clearThreshold: Double,
    val clearHoldMs: Long,
) {
    companion object {
        val DEFAULT_COOLANT = CarAlertPolicy(
            enterThreshold = 105.0,
            enterHoldMs = 3_000L,
            clearThreshold = 100.0,
            clearHoldMs = 10_000L,
        )
    }
}

/**
 * Hysteresis and hold-time alert evaluator.
 *
 * Implements a strict two-threshold, time-debounced state machine:
 * - Enter: value >= enterThreshold held continuously for enterHoldMs -> ACTIVE
 * - Clear: value <= clearThreshold held continuously for clearHoldMs -> NORMAL
 * - Stale defense: if the sensor signal becomes stale or unavailable while an alert
 *   was ACTIVE or PENDING_CLEAR, it enters UNKNOWN_AFTER_WARNING and NEVER resets
 *   to NORMAL without observing valid readings continuously below clearThreshold.
 */
class CarAlertEvaluator(
    private val policy: CarAlertPolicy = CarAlertPolicy.DEFAULT_COOLANT,
) {
    var phase: CarAlertPhase = CarAlertPhase.NORMAL
        private set

    private var pendingEnterStartMs: Long = 0L
    private var pendingClearStartMs: Long = 0L

    val isAlertActive: Boolean
        get() = phase == CarAlertPhase.ACTIVE ||
                phase == CarAlertPhase.PENDING_CLEAR ||
                phase == CarAlertPhase.UNKNOWN_AFTER_WARNING

    fun evaluate(value: Double?, isLive: Boolean, elapsedMs: Long): CarAlertPhase {
        if (!isLive || value == null || !value.isFinite()) {
            phase = when (phase) {
                CarAlertPhase.ACTIVE, CarAlertPhase.PENDING_CLEAR, CarAlertPhase.UNKNOWN_AFTER_WARNING ->
                    CarAlertPhase.UNKNOWN_AFTER_WARNING
                CarAlertPhase.NORMAL, CarAlertPhase.PENDING_ENTER ->
                    CarAlertPhase.NORMAL
            }
            return phase
        }

        when (phase) {
            CarAlertPhase.NORMAL -> {
                if (value >= policy.enterThreshold) {
                    phase = CarAlertPhase.PENDING_ENTER
                    pendingEnterStartMs = elapsedMs
                    if (policy.enterHoldMs <= 0L) {
                        phase = CarAlertPhase.ACTIVE
                    }
                }
            }
            CarAlertPhase.PENDING_ENTER -> {
                if (value < policy.enterThreshold) {
                    phase = CarAlertPhase.NORMAL
                } else if (elapsedMs - pendingEnterStartMs >= policy.enterHoldMs) {
                    phase = CarAlertPhase.ACTIVE
                }
            }
            CarAlertPhase.ACTIVE -> {
                if (value <= policy.clearThreshold) {
                    phase = CarAlertPhase.PENDING_CLEAR
                    pendingClearStartMs = elapsedMs
                    if (policy.clearHoldMs <= 0L) {
                        phase = CarAlertPhase.NORMAL
                    }
                }
            }
            CarAlertPhase.PENDING_CLEAR -> {
                if (value > policy.clearThreshold) {
                    phase = CarAlertPhase.ACTIVE
                } else if (elapsedMs - pendingClearStartMs >= policy.clearHoldMs) {
                    phase = CarAlertPhase.NORMAL
                }
            }
            CarAlertPhase.UNKNOWN_AFTER_WARNING -> {
                if (value <= policy.clearThreshold) {
                    phase = CarAlertPhase.PENDING_CLEAR
                    pendingClearStartMs = elapsedMs
                    if (policy.clearHoldMs <= 0L) {
                        phase = CarAlertPhase.NORMAL
                    }
                } else {
                    phase = CarAlertPhase.ACTIVE
                }
            }
        }
        return phase
    }

    fun reset() {
        phase = CarAlertPhase.NORMAL
        pendingEnterStartMs = 0L
        pendingClearStartMs = 0L
    }
}

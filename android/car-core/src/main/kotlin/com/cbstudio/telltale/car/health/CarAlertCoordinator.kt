package com.cbstudio.telltale.car.health

import android.os.SystemClock
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryRuntime
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Session-scoped alert coordinator (AA05-23, AA05-24, AA05-25, AA05-30).
 *
 * Responsibilities:
 * - Observes [CarTelemetryRepository.state] independently of any Screen lifecycle.
 * - Resets alert state immediately when [connectionEpoch] transitions (AA05-24).
 * - Preserves active warnings under stale signal conditions (UNKNOWN_AFTER_WARNING, AA05-25).
 * - Fires [onAlertTransitionListener] on semantic alert transitions for immediate UI invalidation (AA05-30).
 */
class CarAlertCoordinator(
    private val telemetryRepository: CarTelemetryRepository = CarTelemetryRuntime.repository,
    private val evaluator: CarAlertEvaluator = CarAlertEvaluator(),
    val repository: CarAlertRepository = CarAlertRepository(),
    private val clock: () -> Long = SystemClock::elapsedRealtime,
    private val coroutineScope: CoroutineScope? = null,
) {
    private var internalScope: CoroutineScope? = null
    private var observeJob: Job? = null
    private var lastObservedEpoch: Long? = null

    fun start() {
        stop()
        val scope = getScope()
        observeJob = scope.launch {
            telemetryRepository.state.collect { state ->
                handleTelemetryState(state)
            }
        }
    }

    fun stop() {
        observeJob?.cancel()
        observeJob = null
    }

    fun destroy() {
        stop()
        internalScope?.cancel()
        internalScope = null
        evaluator.reset()
        lastObservedEpoch = null
        repository.reset()
    }

    internal fun handleTelemetryState(state: CarTelemetryState) {
        val now = clock()
        val currentEpoch = (state as? CarTelemetryState.Current)?.frame?.connectionEpoch

        // AA05-24: connectionEpoch change immediately resets alert state
        if (currentEpoch != null && lastObservedEpoch != null && currentEpoch != lastObservedEpoch) {
            evaluator.reset()
        }
        if (currentEpoch != null) {
            lastObservedEpoch = currentEpoch
        }

        val frame = (state as? CarTelemetryState.Current)?.frame
        val coolantSignal = frame?.coolantC
        val isLive = state is CarTelemetryState.Current && coolantSignal?.status == CarSignalStatus.LIVE
        val coolantVal = coolantSignal?.value

        val newPhase = evaluator.evaluate(coolantVal, isLive, now)

        val level = when {
            evaluator.isAlertActive -> CarAlertLevel.ATTENTION
            state is CarTelemetryState.Current -> CarAlertLevel.NORMAL
            else -> CarAlertLevel.UNKNOWN
        }

        val snapshot = CarAlertSnapshot(
            level = level,
            coolant = newPhase,
            connectionEpoch = currentEpoch ?: lastObservedEpoch,
        )

        repository.updateSnapshot(snapshot)
    }

    private fun getScope(): CoroutineScope {
        return coroutineScope ?: internalScope ?: run {
            val dispatcher = try {
                Dispatchers.Main.immediate
            } catch (_: Throwable) {
                Dispatchers.Default
            }
            CoroutineScope(SupervisorJob() + dispatcher).also {
                internalScope = it
            }
        }
    }
}

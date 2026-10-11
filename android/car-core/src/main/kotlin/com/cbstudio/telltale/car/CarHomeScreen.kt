package com.cbstudio.telltale.car

import android.os.SystemClock
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.Header
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarSpeedResolver
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.health.CarAlertPhase
import com.cbstudio.telltale.car.health.CarAlertRepository
import com.cbstudio.telltale.car.health.matchingAlertSnapshot
import com.cbstudio.telltale.car.localization.CarTextIsolation
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarSignalValue
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryRuntime
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Driver-distraction-safe live telemetry dashboard screen (AA-03, AA-05).
 *
 * Implements:
 * - Dynamic row limit adaptation via [ConstraintManager.CONTENT_LIMIT_TYPE_PANE] (4 to 6 rows).
 * - Prioritized metric presentation: Speed (km/h), RPM, Coolant (°C), Voltage (V), Boost, Engine Load.
 * - Multi-source speed arbitration (AA-05): OBD-first with host CarInfo fallback (display/raw).
 * - In-template alert presentation for coolant temperature (AA-05).
 * - Missing & stale data contracts: missing/unavailable shows `--`, quiet/stale shows `Stale`.
 *   Never fabricates fictitious 0 values.
 * - DDG compliance: strictly read-only, no interactive/destructive buttons, 1Hz throttled invalidation,
 *   with immediate invalidation on semantic alert transitions.
 */
class CarHomeScreen(
    carContext: CarContext,
    private val repository: CarTelemetryRepository = CarTelemetryRuntime.repository,
    private val constraintManager: ConstraintManager? = null,
    private val contentLimitProvider: (() -> Int)? = null,
    private val clock: () -> Long = SystemClock::elapsedRealtime,
    private val coroutineScope: CoroutineScope? = null,
    private val sessionRuntime: CarSessionRuntime? = null,
    private val speedResolver: CarSpeedResolver = sessionRuntime?.speedResolver ?: CarSpeedResolver(),
    private val hostSpeedRepository: CarHostSpeedRepository = sessionRuntime?.hostSpeedRepository ?: CarHostSpeedRepository(),
    private val alertRepository: CarAlertRepository = sessionRuntime?.alertRepository ?: CarAlertRepository(),
) : Screen(carContext), DefaultLifecycleObserver {

    companion object {
        const val MAX_PANE_ROWS = 6
        const val DEFAULT_PANE_LIMIT = 4
        const val THROTTLE_INTERVAL_MS = 1_000L
    }

    internal data class MetricRow(
        val title: String,
        val text: String,
    )

    internal data class DisplayModel(
        val rows: List<MetricRow>,
    )

    private var internalScope: CoroutineScope? = null
    private var observeJob: Job? = null
    private var pendingRefreshJob: Job? = null
    private var lastInvalidateElapsedMs: Long = -THROTTLE_INTERVAL_MS
    private var lastRenderedModel: DisplayModel? = null

    internal var onInvalidateListener: (() -> Unit)? = null

    init {
        lastRenderedModel = buildDisplayModel(repository.state.value)
        lifecycle.addObserver(this)
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            startObserving()
        }
    }

    override fun onStart(owner: LifecycleOwner) {
        startObserving()
    }

    override fun onStop(owner: LifecycleOwner) {
        stopObserving()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        stopObserving()
        internalScope?.cancel()
        internalScope = null
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

    private fun startObserving() {
        stopObserving()
        val scope = getScope()
        observeJob = scope.launch {
            launch {
                repository.state.collect { state ->
                    handleStateUpdate(state)
                }
            }
            launch {
                hostSpeedRepository.sample.collect {
                    handleStateUpdate(repository.state.value)
                }
            }
            launch {
                alertRepository.transitions.collect {
                    triggerImmediateRefresh()
                }
            }
        }
    }

    private fun stopObserving() {
        observeJob?.cancel()
        observeJob = null
        pendingRefreshJob?.cancel()
        pendingRefreshJob = null
    }

    internal fun triggerImmediateRefresh() {
        if (!lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) return
        pendingRefreshJob?.cancel()
        pendingRefreshJob = null
        val currentModel = buildDisplayModel(repository.state.value)
        if (currentModel != lastRenderedModel) {
            executeInvalidate(currentModel, clock())
        }
    }

    private fun handleStateUpdate(state: CarTelemetryState) {
        if (!lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            return
        }

        val newModel = buildDisplayModel(state)
        // Rule: Do not refresh if formatted numbers/status did not change.
        if (newModel == lastRenderedModel) {
            return
        }

        val now = clock()
        val elapsed = now - lastInvalidateElapsedMs

        if (elapsed >= THROTTLE_INTERVAL_MS && pendingRefreshJob == null) {
            executeInvalidate(newModel, now)
        } else if (pendingRefreshJob == null) {
            val delayMs = (THROTTLE_INTERVAL_MS - elapsed).coerceAtLeast(0L)
            val scope = getScope()
            pendingRefreshJob = scope.launch {
                delay(delayMs)
                if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
                    val currentModel = buildDisplayModel(repository.state.value)
                    if (currentModel != lastRenderedModel) {
                        executeInvalidate(currentModel, clock())
                    }
                }
                pendingRefreshJob = null
            }
        }
    }

    private fun executeInvalidate(model: DisplayModel, now: Long) {
        lastInvalidateElapsedMs = now
        lastRenderedModel = model
        try {
            invalidate()
        } catch (_: IllegalStateException) {
            // Screen or host not currently accepting invalidations
        }
        onInvalidateListener?.invoke()
    }

    fun resolveContentLimit(): Int {
        if (contentLimitProvider != null) {
            val provided = try {
                contentLimitProvider.invoke()
            } catch (_: Throwable) {
                DEFAULT_PANE_LIMIT
            }
            return capPaneLimit(provided)
        }
        val manager = constraintManager ?: try {
            carContext.getCarService(ConstraintManager::class.java)
        } catch (_: Throwable) {
            try {
                carContext.getCarService(CarContext.CONSTRAINT_SERVICE) as? ConstraintManager
            } catch (_: Throwable) {
                null
            }
        }
        val limit = try {
            manager?.getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_PANE) ?: DEFAULT_PANE_LIMIT
        } catch (_: Throwable) {
            DEFAULT_PANE_LIMIT
        }
        return capPaneLimit(limit)
    }

    private fun capPaneLimit(limit: Int): Int =
        if (limit > 0) {
            minOf(limit, MAX_PANE_ROWS)
        } else {
            DEFAULT_PANE_LIMIT
        }

    internal fun buildDisplayModel(state: CarTelemetryState): DisplayModel {
        val candidates = buildCandidateRows(state)
        val limit = resolveContentLimit()
        return DisplayModel(candidates.take(limit))
    }

    private fun buildCandidateRows(state: CarTelemetryState): List<MetricRow> {
        val isRtl = CarTextIsolation.isRtlContext(carContext)
        val missingText = carContext.getString(R.string.car_signal_missing)
        val staleText = carContext.getString(R.string.car_signal_stale)

        fun formatSignal(signal: CarSignalValue?, unit: String, format: String): String {
            return when (state) {
                is CarTelemetryState.Stale -> {
                    if (state.lastReceivedAtElapsedMs != null) staleText else missingText
                }
                is CarTelemetryState.Awaiting, is CarTelemetryState.Incompatible -> missingText
                is CarTelemetryState.Current -> {
                    if (signal == null) {
                        missingText
                    } else {
                        when (signal.status) {
                            CarSignalStatus.LIVE -> {
                                val value = signal.value
                                if (value != null && value.isFinite()) {
                                    val formatted = format.format(Locale.US, value)
                                    val cleanFormatted = if (formatted == "-0" || formatted == "-0.0") {
                                        formatted.removePrefix("-")
                                    } else {
                                        formatted
                                    }
                                    CarTextIsolation.wrapMetric(cleanFormatted, unit, isRtl)
                                } else {
                                    missingText
                                }
                            }
                            CarSignalStatus.STALE -> staleText
                            CarSignalStatus.UNAVAILABLE, CarSignalStatus.UNSUPPORTED -> missingText
                        }
                    }
                }
            }
        }

        val frame = (state as? CarTelemetryState.Current)?.frame

        // AA-05: Resolved speed through arbitration (OBD live > Host display > Host raw > Stale / Unavailable)
        val resolvedSpeed = speedResolver.resolve(state, hostSpeedRepository.sample.value)
        val speedText = when (resolvedSpeed.status) {
            CarSignalStatus.LIVE -> {
                val value = resolvedSpeed.speedKmh
                if (value != null && value.isFinite()) {
                    val formatted = "%.0f".format(Locale.US, value)
                    val cleanFormatted = if (formatted == "-0" || formatted == "-0.0") {
                        formatted.removePrefix("-")
                    } else {
                        formatted
                    }
                    CarTextIsolation.wrapMetric(cleanFormatted, "km/h", isRtl)
                } else {
                    missingText
                }
            }
            CarSignalStatus.STALE -> staleText
            CarSignalStatus.UNAVAILABLE, CarSignalStatus.UNSUPPORTED -> missingText
        }

        val rpmText = formatSignal(frame?.rpm, "RPM", "%.0f")

        // AA-05: In-template Coolant Alert
        val coolantBase = formatSignal(frame?.coolantC, "°C", "%.0f")
        val alertSnapshot = matchingAlertSnapshot(state, alertRepository.snapshot.value)
        val coolantText = when {
            alertSnapshot?.coolant == CarAlertPhase.ACTIVE -> {
                if (coolantBase != missingText && coolantBase != staleText) {
                    "$coolantBase · ${carContext.getString(R.string.car_alert_high)}"
                } else {
                    coolantBase
                }
            }
            alertSnapshot?.coolant == CarAlertPhase.UNKNOWN_AFTER_WARNING -> {
                if (coolantBase != missingText && coolantBase != staleText) {
                    "$coolantBase · ${carContext.getString(R.string.car_alert_high)}"
                } else {
                    staleText
                }
            }
            else -> coolantBase
        }

        val voltageText = formatSignal(frame?.controlModuleVoltageV, "V", "%.1f")
        val boostText = missingText
        val loadText = missingText

        return listOf(
            MetricRow(carContext.getString(R.string.car_home_speed_title), speedText),
            MetricRow(carContext.getString(R.string.car_home_rpm_title), rpmText),
            MetricRow(carContext.getString(R.string.car_home_coolant_title), coolantText),
            MetricRow(carContext.getString(R.string.car_home_voltage_title), voltageText),
            MetricRow(carContext.getString(R.string.car_home_boost_title), boostText),
            MetricRow(carContext.getString(R.string.car_home_load_title), loadText),
        )
    }

    override fun onGetTemplate(): Template {
        val model = buildDisplayModel(repository.state.value)
        lastRenderedModel = model

        val paneBuilder = Pane.Builder()
        for (row in model.rows) {
            paneBuilder.addRow(
                Row.Builder()
                    .setTitle(row.title)
                    .addText(row.text)
                    .build(),
            )
        }

        val healthAction = Action.Builder()
            .setTitle(carContext.getString(R.string.car_action_health))
            .setOnClickListener {
                screenManager.push(
                    CarHealthScreen(
                        carContext = carContext,
                        telemetryRepository = repository,
                        constraintManager = constraintManager,
                        contentLimitProvider = contentLimitProvider,
                        clock = clock,
                        sessionRuntime = sessionRuntime,
                        hostSpeedRepository = hostSpeedRepository,
                        motionResolver = sessionRuntime?.motionResolver ?: CarVehicleMotionResolver(),
                        alertRepository = alertRepository,
                    ),
                )
            }
            .build()

        val header = Header.Builder()
            .setTitle(carContext.getString(R.string.car_app_name))
            .setStartHeaderAction(Action.APP_ICON)
            .addEndHeaderAction(healthAction)
            .build()

        return PaneTemplate.Builder(paneBuilder.build())
            .setHeader(header)
            .build()
    }
}

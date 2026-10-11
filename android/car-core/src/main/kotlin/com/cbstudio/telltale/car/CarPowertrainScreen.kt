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
 * Driver-distraction-safe powertrain overview screen (AA-04B, AA-05).
 *
 * Displays actual available powertrain metrics from schema-v1:
 * RPM, Coolant, Intake Air (IAT), Manifold Absolute Pressure (MAP), Module Voltage, Speed.
 * Read-only, 1Hz throttled invalidation, dynamic host content limit compliance,
 * with speed arbitration fallback and coolant in-template alerts.
 */
class CarPowertrainScreen(
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
        val icon: CarMetricIcon,
        val warning: Boolean = false,
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

        val rpmText = formatSignal(frame?.rpm, "RPM", "%.0f")

        // Coolant with alert status
        val coolantBase = formatSignal(frame?.coolantC, "°C", "%.0f")
        val alertSnapshot = matchingAlertSnapshot(state, alertRepository.snapshot.value)
        val coolantWarning = alertSnapshot?.coolant == CarAlertPhase.ACTIVE ||
                alertSnapshot?.coolant == CarAlertPhase.UNKNOWN_AFTER_WARNING
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

        val iatText = formatSignal(frame?.intakeAirC, "°C", "%.0f")
        val mapText = formatSignal(frame?.mapKpa, "kPa", "%.0f")
        val voltageText = formatSignal(frame?.controlModuleVoltageV, "V", "%.1f")

        // Speed resolved via arbitration
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

        return listOf(
            MetricRow(carContext.getString(R.string.car_powertrain_rpm_title), rpmText, CarMetricIcon.RPM),
            MetricRow(
                carContext.getString(R.string.car_powertrain_coolant_title),
                coolantText,
                CarMetricIcon.TEMPERATURE,
                warning = coolantWarning,
            ),
            MetricRow(carContext.getString(R.string.car_powertrain_iat_title), iatText, CarMetricIcon.TEMPERATURE),
            MetricRow(carContext.getString(R.string.car_powertrain_map_title), mapText, CarMetricIcon.PRESSURE),
            MetricRow(carContext.getString(R.string.car_powertrain_voltage_title), voltageText, CarMetricIcon.VOLTAGE),
            MetricRow(carContext.getString(R.string.car_powertrain_speed_title), speedText, CarMetricIcon.SPEED),
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
                    .setImage(row.icon.toCarIcon(carContext, row.warning), Row.IMAGE_TYPE_SMALL)
                    .build(),
            )
        }

        val header = Header.Builder()
            .setTitle(carContext.getString(R.string.car_powertrain_title))
            .setStartHeaderAction(Action.BACK)
            .build()

        return PaneTemplate.Builder(paneBuilder.build())
            .setHeader(header)
            .build()
    }
}

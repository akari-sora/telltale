package com.cbstudio.telltale.car

import android.os.SystemClock
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.Header
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.versioning.CarAppApiLevels
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.diagnostics.CarDtcRuntime
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
 * Read-only live telemetry dashboard using host-owned templates (AA-03, AA-05, AA-10, AA-11).
 *
 * Implements:
 * - A PaneTemplate whose rows carry the native readings. With [graphicalDashboard] on a Car API 4+
 *   host it adds one large gauge image beside the rows (AA-11); without it, rows only.
 * - Row limit from [ConstraintManager.CONTENT_LIMIT_TYPE_PANE] (capped at 6), resolved once per
 *   screen so row count and titles never change between refreshes.
 * - Prioritized metric presentation: Speed, RPM, Coolant, Voltage, MAP, Engine Load.
 * - Multi-source speed arbitration (AA-05): OBD-first with host CarInfo fallback (display/raw).
 * - In-template alert presentation for coolant temperature (AA-05).
 * - Missing & stale data contracts: missing/unavailable shows `--`, quiet/stale shows `Stale`.
 *   Never fabricates fictitious 0 values.
 * - Read-only telemetry and template navigation, 1Hz throttled invalidation,
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
    private val graphicalDashboard: Boolean = false,
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
        val graphicValue: Double? = null,
        // Gauge image only: the formatted number the native text shows, and what the image may claim.
        val graphicText: String? = null,
        val gaugeState: CarGaugeState = CarGaugeState.NO_DATA,
    )

    internal data class DisplayModel(
        val rows: List<MetricRow>,
    )

    // Resolve once per screen: PaneTemplate refreshes require the same row count and row titles.
    private val rowLimit: Int by lazy { resolveContentLimit() }
    private val gaugeGraphic by lazy { CarGaugeGraphic(carContext) }

    // Pane.Builder.setImage requires Car API 4. Resolved once; an unknown level means rows only.
    private val paneImageSupported: Boolean by lazy {
        graphicalDashboard && try {
            carContext.carAppApiLevel >= CarAppApiLevels.LEVEL_4
        } catch (_: Exception) {
            false
        }
    }

    /** Builds the Pane image; a failure leaves the Pane with its rows only. Replaceable in tests. */
    internal var dashboardImage: (List<MetricRow>, Boolean) -> CarIcon? = { rows, dark ->
        gaugeGraphic.dashboard(
            rows.map { CarGaugeReadout(it.icon, it.graphicValue, it.graphicText, it.gaugeState, it.warning) },
            dark,
        )
    }

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
        return DisplayModel(buildCandidateRows(state).take(rowLimit))
    }

    private fun buildCandidateRows(state: CarTelemetryState): List<MetricRow> {
        val isRtl = CarTextIsolation.isRtlContext(carContext)
        val missingText = carContext.getString(R.string.car_signal_missing)
        val staleText = carContext.getString(R.string.car_signal_stale)

        fun formatNumber(value: Double, format: String): String {
            val formatted = format.format(Locale.US, value)
            return if (formatted == "-0" || formatted == "-0.0") formatted.removePrefix("-") else formatted
        }

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
                                    CarTextIsolation.wrapMetric(formatNumber(value, format), unit, isRtl)
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
        fun graphicNumber(value: Double?, format: String): Double? {
            if (!graphicalDashboard || value == null || !value.isFinite()) return null
            // Match the visible native reading, so invisible precision changes stay quiet.
            val rounded = format.format(Locale.US, value).toDouble()
            return if (rounded == 0.0) 0.0 else rounded
        }
        fun graphicValue(signal: CarSignalValue?, format: String): Double? =
            if (signal?.status == CarSignalStatus.LIVE) graphicNumber(signal.value, format) else null
        fun graphicText(value: Double?, format: String): String? =
            graphicNumber(value, format)?.let { formatNumber(it, format) }

        // Mirrors formatSignal's branches, so the image and the native text claim the same thing.
        fun statusState(status: CarSignalStatus, value: Double?): CarGaugeState = when (status) {
            CarSignalStatus.LIVE ->
                if (value != null && value.isFinite()) CarGaugeState.LIVE else CarGaugeState.NO_DATA
            CarSignalStatus.STALE -> CarGaugeState.STALE
            CarSignalStatus.UNAVAILABLE -> CarGaugeState.NO_DATA
            CarSignalStatus.UNSUPPORTED -> CarGaugeState.UNSUPPORTED
        }
        fun signalState(signal: CarSignalValue?): CarGaugeState {
            if (!graphicalDashboard) return CarGaugeState.NO_DATA
            return when (state) {
                is CarTelemetryState.Stale ->
                    if (state.lastReceivedAtElapsedMs != null) CarGaugeState.STALE else CarGaugeState.NO_DATA
                is CarTelemetryState.Awaiting, is CarTelemetryState.Incompatible -> CarGaugeState.NO_DATA
                is CarTelemetryState.Current ->
                    if (signal == null) CarGaugeState.NO_DATA else statusState(signal.status, signal.value)
            }
        }
        fun liveText(signal: CarSignalValue?, format: String): String? =
            if (signal?.status == CarSignalStatus.LIVE) graphicText(signal.value, format) else null

        // AA-05: Resolved speed through arbitration (OBD live > Host display > Host raw > Stale / Unavailable)
        val resolvedSpeed = speedResolver.resolve(state, hostSpeedRepository.sample.value)
        val speedText = when (resolvedSpeed.status) {
            CarSignalStatus.LIVE -> {
                val value = resolvedSpeed.speedKmh
                if (value != null && value.isFinite()) {
                    CarTextIsolation.wrapMetric(formatNumber(value, "%.0f"), "km/h", isRtl)
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
        // An unknown-after-warning coolant without a reading is shown as Stale by the native text.
        val coolantState = signalState(frame?.coolantC).let {
            if (graphicalDashboard && alertSnapshot?.coolant == CarAlertPhase.UNKNOWN_AFTER_WARNING &&
                (coolantBase == missingText || coolantBase == staleText)
            ) CarGaugeState.STALE else it
        }
        val speedLive = resolvedSpeed.status == CarSignalStatus.LIVE

        val voltageText = formatSignal(frame?.controlModuleVoltageV, "V", "%.1f")
        val mapText = formatSignal(frame?.mapKpa, "kPa", "%.0f")
        val loadText = formatSignal(frame?.engineLoadPct, "%", "%.0f")

        return listOf(
            MetricRow(
                carContext.getString(R.string.car_home_speed_title), speedText, CarMetricIcon.SPEED,
                graphicValue = if (speedLive) graphicNumber(resolvedSpeed.speedKmh, "%.0f") else null,
                graphicText = if (speedLive) graphicText(resolvedSpeed.speedKmh, "%.0f") else null,
                gaugeState = if (!graphicalDashboard) {
                    CarGaugeState.NO_DATA
                } else {
                    statusState(resolvedSpeed.status, resolvedSpeed.speedKmh)
                },
            ),
            MetricRow(
                carContext.getString(R.string.car_home_rpm_title), rpmText, CarMetricIcon.RPM,
                graphicValue = graphicValue(frame?.rpm, "%.0f"),
                graphicText = liveText(frame?.rpm, "%.0f"),
                gaugeState = signalState(frame?.rpm),
            ),
            MetricRow(
                carContext.getString(R.string.car_home_coolant_title),
                coolantText,
                CarMetricIcon.TEMPERATURE,
                warning = coolantWarning,
                graphicValue = graphicValue(frame?.coolantC, "%.0f"),
                graphicText = liveText(frame?.coolantC, "%.0f"),
                gaugeState = coolantState,
            ),
            MetricRow(
                carContext.getString(R.string.car_home_voltage_title),
                voltageText, CarMetricIcon.VOLTAGE,
                graphicValue = graphicValue(frame?.controlModuleVoltageV, "%.1f"),
                graphicText = liveText(frame?.controlModuleVoltageV, "%.1f"),
                gaugeState = signalState(frame?.controlModuleVoltageV),
            ),
            MetricRow(carContext.getString(R.string.car_powertrain_map_title), mapText, CarMetricIcon.PRESSURE),
            MetricRow(carContext.getString(R.string.car_home_load_title), loadText, CarMetricIcon.LOAD),
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
        // The image only repeats what the rows say, so any failure simply leaves it out.
        if (paneImageSupported) {
            val image = try {
                dashboardImage(model.rows, carContext.isDarkMode)
            } catch (_: Exception) {
                null
            }
            image?.let(paneBuilder::setImage)
        }

        val healthAction = Action.Builder()
            .setTitle(carContext.getString(R.string.car_action_health))
            .setOnClickListener { openHealth() }
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

    private fun openHealth() {
        screenManager.push(
            CarHealthScreen(
                carContext = carContext,
                telemetryRepository = repository,
                dtcRepository = sessionRuntime?.dtcRepository ?: CarDtcRuntime.repository,
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
}

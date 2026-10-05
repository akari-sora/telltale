package com.cbstudio.telltale.car

import android.os.SystemClock
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.ParkedOnlyOnClickListener
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcRepository
import com.cbstudio.telltale.car.diagnostics.CarDtcRuntime
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.hardware.CarHostSpeedPermissionCoordinator
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.health.CarAlertLevel
import com.cbstudio.telltale.car.health.CarAlertPhase
import com.cbstudio.telltale.car.health.CarAlertRepository
import com.cbstudio.telltale.car.health.CarHealthEvaluator
import com.cbstudio.telltale.car.health.CarObservedHealth
import com.cbstudio.telltale.car.health.matchingAlertSnapshot
import com.cbstudio.telltale.car.safety.CarDtcMotionGate
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
 * Driver-distraction-safe vehicle health overview screen (AA-04B, AA-05).
 *
 * Implements:
 * - Observed vehicle health summary: "No observed warnings", "Attention", or "Unknown".
 *   Never fabricates "Safe to drive" or "Healthy".
 * - Driving-safe overview: MIL status, DTC count, Coolant temperature, Module Voltage.
 * - Hysteresis-guarded alerts for critical sensor readings (e.g. high coolant) via [CarAlertRepository].
 * - Parked-only navigation gate to [CarDtcSummaryScreen] using [ParkedOnlyOnClickListener] and [CarDtcMotionGate]
 *   with multi-source motion fusion (AA-05).
 * - 1Hz throttled invalidation, dynamic host content limit compliance.
 */
class CarHealthScreen(
    carContext: CarContext,
    private val telemetryRepository: CarTelemetryRepository = CarTelemetryRuntime.repository,
    private val dtcRepository: CarDtcRepository = CarDtcRuntime.repository,
    private val constraintManager: ConstraintManager? = null,
    private val contentLimitProvider: (() -> Int)? = null,
    private val clock: () -> Long = SystemClock::elapsedRealtime,
    private val coroutineScope: CoroutineScope? = null,
    private val sessionRuntime: CarSessionRuntime? = null,
    private val hostSpeedRepository: CarHostSpeedRepository = sessionRuntime?.hostSpeedRepository ?: CarHostSpeedRepository(),
    private val motionResolver: CarVehicleMotionResolver = sessionRuntime?.motionResolver ?: CarVehicleMotionResolver(),
    private val alertRepository: CarAlertRepository = sessionRuntime?.alertRepository ?: CarAlertRepository(),
    private val permissionCoordinator: CarHostSpeedPermissionCoordinator = sessionRuntime?.permissionCoordinator ?: CarHostSpeedPermissionCoordinator(),
) : Screen(carContext), DefaultLifecycleObserver {

    companion object {
        const val CAR_HEALTH_MARKER = "car_health_marker"
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
        setMarker(CAR_HEALTH_MARKER)
        lastRenderedModel = buildDisplayModel(telemetryRepository.state.value, dtcRepository.state.value)
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
                telemetryRepository.state.collect { telemetryState ->
                    handleStateUpdate(telemetryState, dtcRepository.state.value)
                }
            }
            launch {
                dtcRepository.state.collect { dtcState ->
                    handleStateUpdate(telemetryRepository.state.value, dtcState)
                }
            }
            launch {
                hostSpeedRepository.sample.collect {
                    handleStateUpdate(telemetryRepository.state.value, dtcRepository.state.value)
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
        val currentModel = buildDisplayModel(
            telemetryRepository.state.value,
            dtcRepository.state.value,
        )
        if (currentModel != lastRenderedModel) {
            executeInvalidate(currentModel, clock())
        }
    }

    private fun handleStateUpdate(telemetryState: CarTelemetryState, dtcState: CarDtcState) {
        if (!lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            return
        }

        val newModel = buildDisplayModel(telemetryState, dtcState)
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
                    val currentModel = buildDisplayModel(
                        telemetryRepository.state.value,
                        dtcRepository.state.value,
                    )
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

    internal fun buildDisplayModel(
        telemetryState: CarTelemetryState,
        dtcState: CarDtcState,
    ): DisplayModel {
        val candidates = buildCandidateRows(telemetryState, dtcState)
        val limit = resolveContentLimit()
        return DisplayModel(candidates.take(limit))
    }

    private fun buildCandidateRows(
        telemetryState: CarTelemetryState,
        dtcState: CarDtcState,
    ): List<MetricRow> {
        val missingText = carContext.getString(R.string.car_signal_missing)
        val staleText = carContext.getString(R.string.car_signal_stale)

        val frame = (telemetryState as? CarTelemetryState.Current)?.frame
        val dtcReport = com.cbstudio.telltale.car.health.matchingDtcReport(telemetryState, dtcState)

        // 1. Evaluate alert state from session authority (AA-05, Blocker 3)
        val alertSnapshot = matchingAlertSnapshot(telemetryState, alertRepository.snapshot.value)
        val isAlertActive = alertSnapshot?.level == CarAlertLevel.ATTENTION

        // 2. Evaluate observed health
        val observedHealth = CarHealthEvaluator.evaluate(
            telemetryState = telemetryState,
            dtcState = dtcState,
            isAlertActive = isAlertActive,
        )
        val healthText = when (observedHealth) {
            CarObservedHealth.NO_OBSERVED_WARNINGS ->
                carContext.getString(R.string.car_health_status_no_warnings)
            CarObservedHealth.ATTENTION ->
                carContext.getString(R.string.car_health_status_attention)
            CarObservedHealth.UNKNOWN ->
                carContext.getString(R.string.car_health_status_unknown)
        }

        // 3. MIL status text
        val milOn = dtcReport?.milOn ?: frame?.milOn
        val milText = when (milOn) {
            true -> carContext.getString(R.string.car_mil_on)
            false -> carContext.getString(R.string.car_mil_off)
            null -> missingText
        }

        // 4. DTC count text
        val dtcCount = dtcReport?.totalCodes ?: frame?.dtcCount
        val dtcText = when {
            dtcCount != null && dtcCount > 0 ->
                carContext.getString(R.string.car_dtc_count_format, dtcCount)
            dtcCount == 0L ->
                carContext.getString(R.string.car_dtc_none)
            dtcReport != null && dtcReport.items.isNotEmpty() ->
                carContext.getString(R.string.car_dtc_count_format, dtcReport.items.size)
            else -> missingText
        }

        // 5. Signals: Coolant & Module Voltage
        fun formatSignal(signal: CarSignalValue?, unit: String, format: String): String {
            return when (telemetryState) {
                is CarTelemetryState.Stale -> {
                    if (telemetryState.lastReceivedAtElapsedMs != null) staleText else missingText
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
                                    val clean = if (formatted == "-0" || formatted == "-0.0") {
                                        formatted.removePrefix("-")
                                    } else {
                                        formatted
                                    }
                                    "$clean $unit"
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

        val coolantBase = formatSignal(frame?.coolantC, "°C", "%.0f")
        val coolantText = when {
            isAlertActive -> {
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

        return listOf(
            MetricRow(carContext.getString(R.string.car_health_status_row), healthText),
            MetricRow(carContext.getString(R.string.car_health_mil_row), milText),
            MetricRow(carContext.getString(R.string.car_health_dtc_row), dtcText),
            MetricRow(carContext.getString(R.string.car_health_coolant_row), coolantText),
            MetricRow(carContext.getString(R.string.car_health_voltage_row), voltageText),
        )
    }

    internal fun requestSpeedPermission(onResult: ((Boolean) -> Unit)? = null) {
        permissionCoordinator.requestPermissions(carContext) { granted ->
            if (granted) {
                try {
                    invalidate()
                } catch (_: Throwable) {
                }
            }
            onResult?.invoke(granted)
        }
    }

    @Suppress("DEPRECATION")
    override fun onGetTemplate(): Template {
        val model = buildDisplayModel(telemetryRepository.state.value, dtcRepository.state.value)
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

        // Action 1: Powertrain glanceable screen
        paneBuilder.addAction(
            Action.Builder()
                .setTitle(carContext.getString(R.string.car_action_powertrain))
                .setOnClickListener {
                    screenManager.push(
                        CarPowertrainScreen(
                            carContext = carContext,
                            repository = telemetryRepository,
                            constraintManager = constraintManager,
                            contentLimitProvider = contentLimitProvider,
                            clock = clock,
                            sessionRuntime = sessionRuntime,
                            hostSpeedRepository = hostSpeedRepository,
                            alertRepository = alertRepository,
                        ),
                    )
                }
                .build(),
        )

        // Action 2: Fault codes (Parked Only gate)
        paneBuilder.addAction(
            Action.Builder()
                .setTitle(carContext.getString(R.string.car_action_fault_codes))
                .setOnClickListener(
                    ParkedOnlyOnClickListener.create {
                        if (CarDtcMotionGate.isStationary(telemetryRepository.state.value, hostSpeedRepository.sample.value, motionResolver)) {
                            screenManager.push(
                                CarDtcSummaryScreen(
                                    carContext = carContext,
                                    telemetryRepository = telemetryRepository,
                                    dtcRepository = dtcRepository,
                                    constraintManager = constraintManager,
                                    contentLimitProvider = contentLimitProvider,
                                    sessionRuntime = sessionRuntime,
                                    hostSpeedRepository = hostSpeedRepository,
                                    motionResolver = motionResolver,
                                ),
                            )
                        }
                    },
                )
                .build(),
        )

        val templateBuilder = PaneTemplate.Builder(paneBuilder.build())
            .setTitle(carContext.getString(R.string.car_health_title))
            .setHeaderAction(Action.BACK)

        if (hostSpeedRepository.sample.value.status == CarHostSpeedStatus.PERMISSION_DENIED) {
            val actionStrip = ActionStrip.Builder()
                .addAction(
                    Action.Builder()
                        .setTitle(carContext.getString(R.string.car_action_enable_speed))
                        .setOnClickListener(
                            ParkedOnlyOnClickListener.create {
                                requestSpeedPermission()
                            }
                        )
                        .build()
                )
                .build()
            templateBuilder.setActionStrip(actionStrip)
        }

        return templateBuilder.build()
    }
}

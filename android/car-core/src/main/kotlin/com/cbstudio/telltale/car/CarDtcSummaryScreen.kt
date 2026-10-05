package com.cbstudio.telltale.car

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.ParkedOnlyOnClickListener
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.cbstudio.telltale.car.diagnostics.CarDtcCompleteness
import com.cbstudio.telltale.car.diagnostics.CarDtcItem
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcRepository
import com.cbstudio.telltale.car.diagnostics.CarDtcRuntime
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.safety.CarDtcMotionGate
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryRuntime
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Stationary-only screen listing observed DTCs (AA-04B, AA-05).
 *
 * Implements:
 * - Dynamic list limit adaptation via [ConstraintManager.CONTENT_LIMIT_TYPE_LIST].
 * - Overflow row indicator when DTC count exceeds host content limit.
 * - Parked-only navigation gate to [CarDtcDetailScreen].
 * - Automatically pops back to [CarHealthScreen] if vehicle starts moving (multi-source motion gate).
 */
class CarDtcSummaryScreen(
    carContext: CarContext,
    private val telemetryRepository: CarTelemetryRepository = CarTelemetryRuntime.repository,
    private val dtcRepository: CarDtcRepository = CarDtcRuntime.repository,
    private val constraintManager: ConstraintManager? = null,
    private val contentLimitProvider: (() -> Int)? = null,
    private val coroutineScope: CoroutineScope? = null,
    private val sessionRuntime: CarSessionRuntime? = null,
    private val hostSpeedRepository: CarHostSpeedRepository = sessionRuntime?.hostSpeedRepository ?: CarHostSpeedRepository(),
    private val motionResolver: CarVehicleMotionResolver = sessionRuntime?.motionResolver ?: CarVehicleMotionResolver(),
) : Screen(carContext), DefaultLifecycleObserver {

    companion object {
        const val DEFAULT_LIST_LIMIT = 6
    }

    private var internalScope: CoroutineScope? = null
    private var observeJob: Job? = null

    init {
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
                    handleTelemetryUpdate(telemetryState)
                }
            }
            launch {
                hostSpeedRepository.sample.collect {
                    handleTelemetryUpdate(telemetryRepository.state.value)
                }
            }
            launch {
                dtcRepository.state.collect {
                    if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
                        try {
                            invalidate()
                        } catch (_: Throwable) {
                        }
                    }
                }
            }
        }
    }

    private fun stopObserving() {
        observeJob?.cancel()
        observeJob = null
    }

    private fun handleTelemetryUpdate(telemetryState: CarTelemetryState) {
        if (!lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            return
        }
        // Strict safety rule (AA05-18): If vehicle is no longer stationary, pop to CarHealthScreen immediately
        if (!CarDtcMotionGate.isStationary(telemetryState, hostSpeedRepository.sample.value, motionResolver)) {
            try {
                screenManager.popTo(CarHealthScreen.CAR_HEALTH_MARKER)
            } catch (_: Throwable) {
            }
            return
        }
        try {
            invalidate()
        } catch (_: Throwable) {
        }
    }

    fun resolveListLimit(): Int {
        if (contentLimitProvider != null) {
            val provided = try {
                contentLimitProvider.invoke()
            } catch (_: Throwable) {
                DEFAULT_LIST_LIMIT
            }
            return if (provided > 0) provided else DEFAULT_LIST_LIMIT
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
            manager?.getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_LIST) ?: DEFAULT_LIST_LIMIT
        } catch (_: Throwable) {
            DEFAULT_LIST_LIMIT
        }
        return if (limit > 0) limit else DEFAULT_LIST_LIMIT
    }

    override fun onGetTemplate(): Template {
        val listBuilder = ItemList.Builder()
        val limit = resolveListLimit()

        val currentReport = com.cbstudio.telltale.car.health.matchingDtcReport(telemetryRepository.state.value, dtcRepository.state.value)
        val items = currentReport?.items ?: emptyList()

        if (items.isEmpty()) {
            val emptyTitle = when {
                currentReport == null ->
                    carContext.getString(R.string.car_dtc_status_unavailable)
                currentReport.phase == CarDtcScanPhase.SCANNING ->
                    carContext.getString(R.string.car_dtc_status_scanning)
                currentReport.phase == CarDtcScanPhase.INTERRUPTED ->
                    carContext.getString(R.string.car_dtc_status_unavailable)
                currentReport.verdict == CarDtcVerdict.COMPLETE_CLEAN ->
                    carContext.getString(R.string.car_dtc_no_codes)
                currentReport.verdict == CarDtcVerdict.PARTIAL_CLEAN ->
                    carContext.getString(R.string.car_dtc_status_partial_clean)
                currentReport.verdict == CarDtcVerdict.NOT_SCANNED ->
                    carContext.getString(R.string.car_dtc_status_not_scanned)
                currentReport.verdict == CarDtcVerdict.FAILED ->
                    carContext.getString(R.string.car_dtc_status_unavailable)
                else ->
                    carContext.getString(R.string.car_dtc_status_unavailable)
            }
            listBuilder.addItem(
                Row.Builder()
                    .setTitle(emptyTitle)
                    .build(),
            )
        } else {
            val hasOverflow = items.size > limit
            val displayCount = if (hasOverflow) (limit - 1).coerceAtLeast(0) else items.size
            val displayItems = items.take(displayCount)

            for (item in displayItems) {
                val kindLabel = when (item.kind) {
                    CarDtcKind.STORED -> "Stored"
                    CarDtcKind.PENDING -> "Pending"
                    CarDtcKind.PERMANENT -> "Permanent"
                }
                val coverageText = when (item.completeness) {
                    CarDtcCompleteness.COMPLETE -> carContext.getString(R.string.car_dtc_coverage_complete)
                    CarDtcCompleteness.PARTIAL -> carContext.getString(R.string.car_dtc_coverage_partial)
                }

                val rowBuilder = Row.Builder()
                    .setTitle("${item.code} · $kindLabel")
                    .addText("Controller ${item.sourceId ?: "--"}")
                    .addText(coverageText)
                    .setOnClickListener(
                        ParkedOnlyOnClickListener.create {
                            if (CarDtcMotionGate.isStationary(telemetryRepository.state.value, hostSpeedRepository.sample.value, motionResolver)) {
                                screenManager.push(
                                    CarDtcDetailScreen(
                                        carContext = carContext,
                                        item = item,
                                        dtcRepository = dtcRepository,
                                        telemetryRepository = telemetryRepository,
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

                listBuilder.addItem(rowBuilder.build())
            }

            if (hasOverflow) {
                val overflowCount = items.size - displayCount
                listBuilder.addItem(
                    Row.Builder()
                        .setTitle(carContext.getString(R.string.car_dtc_more_items_format, overflowCount))
                        .build(),
                )
            }
        }

        return ListTemplate.Builder()
            .setTitle(carContext.getString(R.string.car_dtc_summary_title))
            .setHeaderAction(Action.BACK)
            .setSingleList(listBuilder.build())
            .build()
    }
}

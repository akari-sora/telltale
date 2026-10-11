package com.cbstudio.telltale.car

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.Header
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
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
import com.cbstudio.telltale.car.diagnostics.CarFreezeReading
import com.cbstudio.telltale.car.diagnostics.CarFreezeSignalKind
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.health.matchingDtcReport
import com.cbstudio.telltale.car.localization.CarTextIsolation
import com.cbstudio.telltale.car.safety.CarDtcMotionGate
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryRuntime
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Stationary-only detail screen for a specific observed DTC and its freeze-frame data (AA-04B, AA-05).
 *
 * Implements:
 * - Exact DTC identification by code + kind + sourceId.
 * - Dynamic list limit adaptation with freeze-frame truncation indicators.
 * - Multi-source motion safety gate: auto-pops back to [CarHealthScreen] if vehicle starts moving.
 * - Fail-closed liveness check: auto-pops if selected DTC is removed during rescan or vehicle change.
 */
class CarDtcDetailScreen(
    carContext: CarContext,
    val item: CarDtcItem,
    private val dtcRepository: CarDtcRepository = CarDtcRuntime.repository,
    private val telemetryRepository: CarTelemetryRepository = CarTelemetryRuntime.repository,
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

    private fun sameIdentity(a: CarDtcItem, b: CarDtcItem): Boolean =
        a.code == b.code &&
            a.kind == b.kind &&
            a.sourceId == b.sourceId

    private fun checkLivenessAndInvalidate() {
        if (!lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            return
        }
        val telemetryState = telemetryRepository.state.value
        // Strict safety rule (AA05-18): If vehicle is no longer stationary, pop to CarHealthScreen immediately
        if (!CarDtcMotionGate.isStationary(telemetryState, hostSpeedRepository.sample.value, motionResolver)) {
            try {
                screenManager.popTo(CarHealthScreen.CAR_HEALTH_MARKER)
            } catch (_: Throwable) {
                try {
                    screenManager.pop()
                } catch (_: Throwable) {
                }
            }
            return
        }
        val currentReport = matchingDtcReport(telemetryState, dtcRepository.state.value)
        val currentItem = currentReport?.items?.firstOrNull { sameIdentity(it, item) }
        if (currentReport == null || currentItem == null) {
            try {
                screenManager.popTo(CarHealthScreen.CAR_HEALTH_MARKER)
            } catch (_: Throwable) {
                try {
                    screenManager.pop()
                } catch (_: Throwable) {
                }
            }
            return
        }
        try {
            invalidate()
        } catch (_: Throwable) {
        }
    }

    private fun startObserving() {
        stopObserving()
        val scope = getScope()
        observeJob = scope.launch {
            launch {
                telemetryRepository.state.collect {
                    checkLivenessAndInvalidate()
                }
            }
            launch {
                hostSpeedRepository.sample.collect {
                    checkLivenessAndInvalidate()
                }
            }
            launch {
                dtcRepository.state.collect {
                    checkLivenessAndInvalidate()
                }
            }
        }
    }

    private fun stopObserving() {
        observeJob?.cancel()
        observeJob = null
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
            null
        }
        val limit = try {
            manager?.getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_LIST) ?: DEFAULT_LIST_LIMIT
        } catch (_: Throwable) {
            DEFAULT_LIST_LIMIT
        }
        return if (limit > 0) limit else DEFAULT_LIST_LIMIT
    }

    private fun formatFreezeReading(reading: CarFreezeReading, isRtl: Boolean = false): Pair<String, String> {
        val (titleRes, unit, format) = when (reading.signal) {
            CarFreezeSignalKind.SPEED_KMH -> Triple(R.string.car_powertrain_speed_title, "km/h", "%.0f")
            CarFreezeSignalKind.RPM -> Triple(R.string.car_powertrain_rpm_title, "RPM", "%.0f")
            CarFreezeSignalKind.COOLANT_C -> Triple(R.string.car_powertrain_coolant_title, "°C", "%.0f")
            CarFreezeSignalKind.INTAKE_AIR_C -> Triple(R.string.car_powertrain_iat_title, "°C", "%.0f")
            CarFreezeSignalKind.ENGINE_LOAD_PCT -> Triple(R.string.car_home_load_title, "%", "%.0f")
            CarFreezeSignalKind.MAP_KPA -> Triple(R.string.car_powertrain_map_title, "kPa", "%.0f")
            CarFreezeSignalKind.CONTROL_MODULE_VOLTAGE_V -> Triple(R.string.car_powertrain_voltage_title, "V", "%.1f")
        }
        val formatted = format.format(Locale.US, reading.value)
        val clean = if (formatted == "-0" || formatted == "-0.0") formatted.removePrefix("-") else formatted
        return Pair(carContext.getString(titleRes), CarTextIsolation.wrapMetric(clean, unit, isRtl))
    }

    override fun onGetTemplate(): Template {
        // SAFE-04 / SAFE-06: Secondary motion check right before rendering template
        if (!CarDtcMotionGate.isStationary(telemetryRepository.state.value, hostSpeedRepository.sample.value, motionResolver)) {
            try {
                screenManager.popTo(CarHealthScreen.CAR_HEALTH_MARKER)
            } catch (_: Throwable) {
                try {
                    screenManager.pop()
                } catch (_: Throwable) {
                }
            }
            val header = Header.Builder()
                .setTitle(carContext.getString(R.string.car_dtc_detail_title))
                .setStartHeaderAction(Action.BACK)
                .build()

            return ListTemplate.Builder()
                .setHeader(header)
                .setSingleList(
                    ItemList.Builder()
                        .addItem(
                            Row.Builder()
                                .setTitle(carContext.getString(R.string.car_dtc_status_unavailable))
                                .build(),
                        )
                        .build(),
                )
                .build()
        }

        val currentReport = matchingDtcReport(telemetryRepository.state.value, dtcRepository.state.value)
        val currentItem = currentReport?.items?.firstOrNull { sameIdentity(it, item) }

        if (currentReport == null || currentItem == null) {
            // SAFE-05: Actively pop back when report or item is no longer available / epoch mismatch
            try {
                screenManager.popTo(CarHealthScreen.CAR_HEALTH_MARKER)
            } catch (_: Throwable) {
                try {
                    screenManager.pop()
                } catch (_: Throwable) {
                }
            }
            val listBuilder = ItemList.Builder()
                .addItem(
                    Row.Builder()
                        .setTitle(carContext.getString(R.string.car_dtc_status_unavailable))
                        .build(),
                )
            val header = Header.Builder()
                .setTitle(carContext.getString(R.string.car_dtc_detail_title))
                .setStartHeaderAction(Action.BACK)
                .build()

            return ListTemplate.Builder()
                .setHeader(header)
                .setSingleList(listBuilder.build())
                .build()
        }

        val isRtl = CarTextIsolation.isRtlContext(carContext)
        val listBuilder = ItemList.Builder()
        val limit = resolveListLimit()
        var rowCount = 0

        fun addRow(title: String, text: String): Boolean {
            if (rowCount >= limit) return false
            listBuilder.addItem(
                Row.Builder()
                    .setTitle(title)
                    .addText(text)
                    .build(),
            )
            rowCount++
            return true
        }

        // 1. Metadata rows
        val classLabel = when (currentItem.kind) {
            CarDtcKind.STORED -> carContext.getString(R.string.car_dtc_kind_stored)
            CarDtcKind.PENDING -> carContext.getString(R.string.car_dtc_kind_pending)
            CarDtcKind.PERMANENT -> carContext.getString(R.string.car_dtc_kind_permanent)
        }
        addRow(carContext.getString(R.string.car_dtc_detail_class), classLabel)
        addRow(carContext.getString(R.string.car_dtc_detail_controller), currentItem.sourceId ?: "--")

        val coverageText = when (currentItem.completeness) {
            CarDtcCompleteness.COMPLETE -> carContext.getString(R.string.car_dtc_coverage_complete)
            CarDtcCompleteness.PARTIAL -> carContext.getString(R.string.car_dtc_coverage_partial)
        }
        addRow(carContext.getString(R.string.car_dtc_detail_coverage), coverageText)

        // 2. Freeze Frame values
        val freezeFrame = currentReport.freezeFrames.firstOrNull { ff ->
            ff.causeCode == currentItem.code &&
                ff.causeKind == currentItem.kind &&
                ff.causeSourceId == currentItem.sourceId
        }

        val availableSlots = (limit - rowCount).coerceAtLeast(0)
        if (availableSlots > 0) {
            if (freezeFrame == null) {
                val text = if (currentReport.freezeFrameReadIncomplete) {
                    carContext.getString(R.string.car_freeze_frame_read_incomplete)
                } else {
                    carContext.getString(R.string.car_freeze_frame_none)
                }
                addRow(carContext.getString(R.string.car_freeze_frame_section), text)
            } else if (freezeFrame.contentsUnknown) {
                addRow(carContext.getString(R.string.car_freeze_frame_section), carContext.getString(R.string.car_freeze_frame_unknown))
            } else {
                val nonDisplayable = freezeFrame.omittedByProjectionCount + freezeFrame.undecodableCount + freezeFrame.unreadCount
                val isIncompleteMetadata = currentReport.freezeFrameReadIncomplete || nonDisplayable > 0
                val needsSummaryRow = isIncompleteMetadata || (freezeFrame.readings.size > availableSlots)
                val maxReadings = if (needsSummaryRow) (availableSlots - 1).coerceAtLeast(0) else availableSlots

                val readingsToDisplay = freezeFrame.readings.take(maxReadings)
                for (reading in readingsToDisplay) {
                    val (signalTitle, signalText) = formatFreezeReading(reading, isRtl)
                    addRow(signalTitle, signalText)
                }

                if (needsSummaryRow && rowCount < limit) {
                    val notDisplayedFromList = freezeFrame.readings.size - readingsToDisplay.size
                    val totalOmitted = nonDisplayable + notDisplayedFromList
                    val summaryText = if (totalOmitted > 0) {
                        carContext.getString(R.string.car_freeze_frame_incomplete_summary, totalOmitted)
                    } else {
                        carContext.getString(R.string.car_freeze_frame_read_incomplete)
                    }
                    addRow(carContext.getString(R.string.car_freeze_frame_section), summaryText)
                }
            }
        }

        val displayCode = CarTextIsolation.wrapDtcCode(currentItem.code, isRtl)

        val header = Header.Builder()
            .setTitle(displayCode)
            .setStartHeaderAction(Action.BACK)
            .build()

        return ListTemplate.Builder()
            .setHeader(header)
            .setSingleList(listBuilder.build())
            .build()
    }
}

package com.cbstudio.telltale.carbridge

import com.cbstudio.telltale.car.diagnostics.CarDtcCompleteness
import com.cbstudio.telltale.car.diagnostics.CarDtcItem
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcRepository
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.CarFreezeFrame
import com.cbstudio.telltale.car.diagnostics.CarFreezeReading
import com.cbstudio.telltale.car.diagnostics.CarFreezeSignalKind
import com.cbstudio.telltale.carbridge.generated.CarDiagnosticsHostApi
import com.cbstudio.telltale.carbridge.generated.CarDtcItemMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcKindMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcObservationCompletenessMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcReportMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcScanPhaseMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcVerdictMessage
import com.cbstudio.telltale.carbridge.generated.CarFreezeFrameMessage
import com.cbstudio.telltale.carbridge.generated.CarFreezeReadingMessage
import com.cbstudio.telltale.carbridge.generated.CarFreezeSignalKindMessage

/**
 * The carProto-only receiving end of the one-way diagnostics bridge.
 */
class CarDiagnosticsHostApiImpl(
    private val repository: CarDtcRepository,
) : CarDiagnosticsHostApi {

    init {
        repository.reset()
    }

    override fun publishDtcReport(report: CarDtcReportMessage) {
        repository.submit(report.toDtcReport())
    }
}

internal fun CarDtcReportMessage.toDtcReport(): CarDtcReport =
    CarDtcReport(
        schemaVersion = schemaVersion,
        reportSequence = reportSequence,
        connectionEpoch = connectionEpoch,
        phase = phase.toCar(),
        verdict = verdict.toCar(),
        coverageComplete = coverageComplete,
        milOn = milOn,
        totalCodes = totalCodes,
        freezeFrameReadIncomplete = freezeFrameReadIncomplete,
        items = items.map { it.toCar() },
        freezeFrames = freezeFrames.map { it.toCar() },
    )

private fun CarDtcScanPhaseMessage.toCar(): CarDtcScanPhase =
    when (this) {
        CarDtcScanPhaseMessage.IDLE -> CarDtcScanPhase.IDLE
        CarDtcScanPhaseMessage.SCANNING -> CarDtcScanPhase.SCANNING
        CarDtcScanPhaseMessage.INTERRUPTED -> CarDtcScanPhase.INTERRUPTED
    }

private fun CarDtcVerdictMessage.toCar(): CarDtcVerdict =
    when (this) {
        CarDtcVerdictMessage.NOT_SCANNED -> CarDtcVerdict.NOT_SCANNED
        CarDtcVerdictMessage.COMPLETE_CLEAN -> CarDtcVerdict.COMPLETE_CLEAN
        CarDtcVerdictMessage.PARTIAL_CLEAN -> CarDtcVerdict.PARTIAL_CLEAN
        CarDtcVerdictMessage.FAULTS_FOUND -> CarDtcVerdict.FAULTS_FOUND
        CarDtcVerdictMessage.FAILED -> CarDtcVerdict.FAILED
    }

private fun CarDtcKindMessage.toCar(): CarDtcKind =
    when (this) {
        CarDtcKindMessage.STORED -> CarDtcKind.STORED
        CarDtcKindMessage.PENDING -> CarDtcKind.PENDING
        CarDtcKindMessage.PERMANENT -> CarDtcKind.PERMANENT
    }

private fun CarDtcObservationCompletenessMessage.toCar(): CarDtcCompleteness =
    when (this) {
        CarDtcObservationCompletenessMessage.COMPLETE -> CarDtcCompleteness.COMPLETE
        CarDtcObservationCompletenessMessage.PARTIAL -> CarDtcCompleteness.PARTIAL
    }

private fun CarDtcItemMessage.toCar(): CarDtcItem =
    CarDtcItem(
        code = code,
        kind = kind.toCar(),
        sourceId = sourceId,
        isManufacturerSpecific = manufacturerSpecific,
        completeness = completeness.toCar(),
    )

private fun CarFreezeSignalKindMessage.toCar(): CarFreezeSignalKind =
    when (this) {
        CarFreezeSignalKindMessage.SPEED_KMH -> CarFreezeSignalKind.SPEED_KMH
        CarFreezeSignalKindMessage.RPM -> CarFreezeSignalKind.RPM
        CarFreezeSignalKindMessage.COOLANT_C -> CarFreezeSignalKind.COOLANT_C
        CarFreezeSignalKindMessage.INTAKE_AIR_C -> CarFreezeSignalKind.INTAKE_AIR_C
        CarFreezeSignalKindMessage.ENGINE_LOAD_PCT -> CarFreezeSignalKind.ENGINE_LOAD_PCT
        CarFreezeSignalKindMessage.MAP_KPA -> CarFreezeSignalKind.MAP_KPA
        CarFreezeSignalKindMessage.CONTROL_MODULE_VOLTAGE_V -> CarFreezeSignalKind.CONTROL_MODULE_VOLTAGE_V
    }

private fun CarFreezeReadingMessage.toCar(): CarFreezeReading =
    CarFreezeReading(
        signal = signal.toCar(),
        value = value,
    )

private fun CarFreezeFrameMessage.toCar(): CarFreezeFrame =
    CarFreezeFrame(
        sourceId = sourceId,
        frameNumber = frameNumber.toInt(),
        causeCode = causeCode,
        causeKind = causeKind.toCar(),
        causeSourceId = causeSourceId,
        readings = readings.map { it.toCar() },
        undecodableCount = undecodableCount.toInt(),
        unreadCount = unreadCount.toInt(),
        omittedByProjectionCount = omittedByProjectionCount.toInt(),
        contentsUnknown = contentsUnknown,
    )

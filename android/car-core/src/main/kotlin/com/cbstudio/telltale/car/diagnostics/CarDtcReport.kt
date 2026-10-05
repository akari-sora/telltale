package com.cbstudio.telltale.car.diagnostics

enum class CarDtcKind {
    STORED,
    PENDING,
    PERMANENT,
}

enum class CarDtcCompleteness {
    COMPLETE,
    PARTIAL,
}

enum class CarDtcVerdict {
    NOT_SCANNED,
    COMPLETE_CLEAN,
    PARTIAL_CLEAN,
    FAULTS_FOUND,
    FAILED,
}

enum class CarDtcScanPhase {
    IDLE,
    SCANNING,
    INTERRUPTED,
}

enum class CarFreezeSignalKind {
    SPEED_KMH,
    RPM,
    COOLANT_C,
    INTAKE_AIR_C,
    ENGINE_LOAD_PCT,
    MAP_KPA,
    CONTROL_MODULE_VOLTAGE_V,
}

data class CarFreezeReading(
    val signal: CarFreezeSignalKind,
    val value: Double,
)

data class CarFreezeFrame(
    val sourceId: String,
    val frameNumber: Int,
    val causeCode: String,
    val causeKind: CarDtcKind,
    val causeSourceId: String?,
    val readings: List<CarFreezeReading>,
    val undecodableCount: Int,
    val unreadCount: Int,
    val omittedByProjectionCount: Int,
    val contentsUnknown: Boolean,
)

data class CarDtcItem(
    val code: String,
    val kind: CarDtcKind,
    val sourceId: String?,
    val isManufacturerSpecific: Boolean,
    val completeness: CarDtcCompleteness,
)

data class CarDtcReport(
    val schemaVersion: Long,
    val reportSequence: Long,
    val connectionEpoch: Long,
    val phase: CarDtcScanPhase,
    val verdict: CarDtcVerdict,
    val coverageComplete: Boolean,
    val milOn: Boolean?,
    val totalCodes: Long?,
    val freezeFrameReadIncomplete: Boolean,
    val items: List<CarDtcItem>,
    val freezeFrames: List<CarFreezeFrame>,
) {
    companion object {
        const val SCHEMA_VERSION: Long = 1
    }
}

sealed interface CarDtcState {
    data object Awaiting : CarDtcState
    data class Current(val report: CarDtcReport) : CarDtcState
    data class Incompatible(val schemaVersion: Long) : CarDtcState
}

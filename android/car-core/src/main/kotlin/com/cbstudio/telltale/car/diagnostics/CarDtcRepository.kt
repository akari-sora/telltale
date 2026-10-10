package com.cbstudio.telltale.car.diagnostics

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

interface CarDtcRepository {
    val state: StateFlow<CarDtcState>
    val latestValidReport: CarDtcReport?
    fun submit(report: CarDtcReport)
    fun reset()
    fun reset(clearSnapshot: Boolean)
    fun replaySnapshot(expectedEpoch: Long? = null): Boolean
    fun clearSnapshot()
}

class DefaultCarDtcRepository : CarDtcRepository {
    private val lock = Any()
    private val _state = MutableStateFlow<CarDtcState>(CarDtcState.Awaiting)
    override val state: StateFlow<CarDtcState> = _state.asStateFlow()

    private var lastEpoch: Long = -1L
    private var lastSequence: Long = -1L
    private var snapshot: CarDtcReport? = null

    override val latestValidReport: CarDtcReport?
        get() = synchronized(lock) { snapshot }

    override fun submit(report: CarDtcReport) {
        synchronized(lock) {
            if (report.schemaVersion != CarDtcReport.SCHEMA_VERSION) {
                _state.value = CarDtcState.Incompatible(report.schemaVersion)
                return
            }

            if (report.connectionEpoch < lastEpoch) {
                return
            }

            if (report.connectionEpoch > lastEpoch) {
                lastEpoch = report.connectionEpoch
                lastSequence = report.reportSequence
                snapshot = report
                _state.value = CarDtcState.Current(report)
                return
            }

            if (report.reportSequence <= lastSequence) {
                return
            }

            lastSequence = report.reportSequence
            snapshot = report
            _state.value = CarDtcState.Current(report)
        }
    }

    override fun reset() {
        reset(clearSnapshot = true)
    }

    override fun reset(clearSnapshot: Boolean) {
        synchronized(lock) {
            if (clearSnapshot) {
                lastEpoch = -1L
                lastSequence = -1L
                snapshot = null
            }
            _state.value = CarDtcState.Awaiting
        }
    }

    override fun replaySnapshot(expectedEpoch: Long?): Boolean {
        synchronized(lock) {
            val cached = snapshot ?: return false
            if (expectedEpoch != null && cached.connectionEpoch != expectedEpoch) {
                clearSnapshot()
                _state.value = CarDtcState.Awaiting
                return false
            }
            _state.value = CarDtcState.Current(cached)
            return true
        }
    }

    override fun clearSnapshot() {
        synchronized(lock) {
            snapshot = null
            lastEpoch = -1L
            lastSequence = -1L
            _state.value = CarDtcState.Awaiting
        }
    }
}

object CarDtcRuntime {
    val repository: CarDtcRepository = DefaultCarDtcRepository()
}

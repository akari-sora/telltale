package com.cbstudio.telltale.car.diagnostics

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

interface CarDtcRepository {
    val state: StateFlow<CarDtcState>
    fun submit(report: CarDtcReport)
    fun reset()
}

class DefaultCarDtcRepository : CarDtcRepository {
    private val _state = MutableStateFlow<CarDtcState>(CarDtcState.Awaiting)
    override val state: StateFlow<CarDtcState> = _state.asStateFlow()

    private var lastEpoch: Long = -1L
    private var lastSequence: Long = -1L

    override fun submit(report: CarDtcReport) {
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
            _state.value = CarDtcState.Current(report)
            return
        }

        if (report.reportSequence <= lastSequence) {
            return
        }

        lastSequence = report.reportSequence
        _state.value = CarDtcState.Current(report)
    }

    override fun reset() {
        lastEpoch = -1L
        lastSequence = -1L
        _state.value = CarDtcState.Awaiting
    }
}

object CarDtcRuntime {
    val repository: CarDtcRepository = DefaultCarDtcRepository()
}

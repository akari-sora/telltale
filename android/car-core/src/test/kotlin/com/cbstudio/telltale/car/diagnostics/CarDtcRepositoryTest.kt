package com.cbstudio.telltale.car.diagnostics

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CarDtcRepositoryTest {

    private lateinit var repository: DefaultCarDtcRepository

    @Before
    fun setUp() {
        repository = DefaultCarDtcRepository()
    }

    private fun report(
        schemaVersion: Long = CarDtcReport.SCHEMA_VERSION,
        reportSequence: Long = 1,
        connectionEpoch: Long = 1,
        phase: CarDtcScanPhase = CarDtcScanPhase.IDLE,
        verdict: CarDtcVerdict = CarDtcVerdict.NOT_SCANNED,
        coverageComplete: Boolean = false,
        milOn: Boolean? = null,
        totalCodes: Long? = null,
        freezeFrameReadIncomplete: Boolean = false,
        items: List<CarDtcItem> = emptyList(),
        freezeFrames: List<CarFreezeFrame> = emptyList(),
    ) = CarDtcReport(
        schemaVersion = schemaVersion,
        reportSequence = reportSequence,
        connectionEpoch = connectionEpoch,
        phase = phase,
        verdict = verdict,
        coverageComplete = coverageComplete,
        milOn = milOn,
        totalCodes = totalCodes,
        freezeFrameReadIncomplete = freezeFrameReadIncomplete,
        items = items,
        freezeFrames = freezeFrames,
    )

    @Test
    fun initialStateIsAwaiting() {
        assertEquals(CarDtcState.Awaiting, repository.state.value)
    }

    @Test
    fun incompatibleSchemaVersionTransitionsToIncompatible() {
        repository.submit(report(schemaVersion = 99))
        val state = repository.state.value
        assertTrue("Expected Incompatible, was $state", state is CarDtcState.Incompatible)
        assertEquals(99L, (state as CarDtcState.Incompatible).schemaVersion)
    }

    @Test
    fun acceptsValidReportAndUpdatesCurrentState() {
        val rep = report(
            reportSequence = 1,
            connectionEpoch = 1,
            verdict = CarDtcVerdict.COMPLETE_CLEAN,
            totalCodes = 0,
        )
        repository.submit(rep)
        val state = repository.state.value
        assertTrue("Expected Current, was $state", state is CarDtcState.Current)
        assertEquals(rep, (state as CarDtcState.Current).report)
    }

    @Test
    fun ignoresStaleSequenceWithinSameEpoch() {
        repository.submit(report(reportSequence = 5, connectionEpoch = 1))
        assertEquals(5L, (repository.state.value as CarDtcState.Current).report.reportSequence)

        // Lower sequence ignored
        repository.submit(report(reportSequence = 4, connectionEpoch = 1))
        assertEquals(5L, (repository.state.value as CarDtcState.Current).report.reportSequence)

        // Equal sequence ignored
        repository.submit(report(reportSequence = 5, connectionEpoch = 1))
        assertEquals(5L, (repository.state.value as CarDtcState.Current).report.reportSequence)

        // Higher sequence accepted
        repository.submit(report(reportSequence = 6, connectionEpoch = 1))
        assertEquals(6L, (repository.state.value as CarDtcState.Current).report.reportSequence)
    }

    @Test
    fun newerEpochResetsSequenceWindowAndAcceptsLowerSequenceNumber() {
        repository.submit(report(reportSequence = 10, connectionEpoch = 1))
        assertEquals(1L, (repository.state.value as CarDtcState.Current).report.connectionEpoch)

        // New epoch 2 with sequence 1 (lower than 10) must be accepted
        repository.submit(report(reportSequence = 1, connectionEpoch = 2))
        val state = repository.state.value as CarDtcState.Current
        assertEquals(2L, state.report.connectionEpoch)
        assertEquals(1L, state.report.reportSequence)

        // Older epoch 1 must be rejected
        repository.submit(report(reportSequence = 20, connectionEpoch = 1))
        assertEquals(2L, (repository.state.value as CarDtcState.Current).report.connectionEpoch)
    }

    @Test
    fun resetRestoresAwaitingStateAndResetsEpoch() {
        repository.submit(report(reportSequence = 1, connectionEpoch = 5))
        assertTrue(repository.state.value is CarDtcState.Current)

        repository.reset()
        assertEquals(CarDtcState.Awaiting, repository.state.value)

        // After reset, epoch 1 is accepted even though epoch 5 was seen before reset
        repository.submit(report(reportSequence = 1, connectionEpoch = 1))
        val state = repository.state.value as CarDtcState.Current
        assertEquals(1L, state.report.connectionEpoch)
    }
}

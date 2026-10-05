package com.cbstudio.telltale.carbridge

import com.cbstudio.telltale.car.diagnostics.CarDtcCompleteness
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.CarFreezeSignalKind
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.carbridge.generated.CarDtcItemMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcKindMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcObservationCompletenessMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcReportMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcScanPhaseMessage
import com.cbstudio.telltale.carbridge.generated.CarDtcVerdictMessage
import com.cbstudio.telltale.carbridge.generated.CarFreezeFrameMessage
import com.cbstudio.telltale.carbridge.generated.CarFreezeReadingMessage
import com.cbstudio.telltale.carbridge.generated.CarFreezeSignalKindMessage
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CarDiagnosticsHostApiImplTest {

    @Test
    fun decodesEveryFieldIntoDtcRepositoryCurrent() {
        val repo = DefaultCarDtcRepository()
        val api = CarDiagnosticsHostApiImpl(repo)

        val message = CarDtcReportMessage(
            schemaVersion = 1,
            reportSequence = 42,
            connectionEpoch = 3,
            phase = CarDtcScanPhaseMessage.SCANNING,
            verdict = CarDtcVerdictMessage.FAULTS_FOUND,
            coverageComplete = false,
            milOn = true,
            totalCodes = 1,
            freezeFrameReadIncomplete = true,
            items = listOf(
                CarDtcItemMessage(
                    code = "P0300",
                    kind = CarDtcKindMessage.STORED,
                    sourceId = "7E8",
                    manufacturerSpecific = false,
                    completeness = CarDtcObservationCompletenessMessage.COMPLETE,
                ),
            ),
            freezeFrames = listOf(
                CarFreezeFrameMessage(
                    sourceId = "7E8",
                    frameNumber = 0,
                    causeCode = "P0300",
                    causeKind = CarDtcKindMessage.STORED,
                    causeSourceId = "7E8",
                    readings = listOf(
                        CarFreezeReadingMessage(
                            signal = CarFreezeSignalKindMessage.COOLANT_C,
                            value = 105.0,
                        ),
                        CarFreezeReadingMessage(
                            signal = CarFreezeSignalKindMessage.SPEED_KMH,
                            value = 60.0,
                        ),
                    ),
                    undecodableCount = 1,
                    unreadCount = 0,
                    omittedByProjectionCount = 2,
                    contentsUnknown = false,
                ),
            ),
        )

        api.publishDtcReport(message)

        val state = repo.state.value
        assertTrue("Expected Current, was $state", state is CarDtcState.Current)
        val report = (state as CarDtcState.Current).report

        assertEquals(1L, report.schemaVersion)
        assertEquals(42L, report.reportSequence)
        assertEquals(3L, report.connectionEpoch)
        assertEquals(CarDtcScanPhase.SCANNING, report.phase)
        assertEquals(CarDtcVerdict.FAULTS_FOUND, report.verdict)
        assertFalse(report.coverageComplete)
        assertEquals(true, report.milOn)
        assertEquals(1L, report.totalCodes)
        assertTrue(report.freezeFrameReadIncomplete)

        assertEquals(1, report.items.size)
        val item = report.items[0]
        assertEquals("P0300", item.code)
        assertEquals(CarDtcKind.STORED, item.kind)
        assertEquals("7E8", item.sourceId)
        assertFalse(item.isManufacturerSpecific)
        assertEquals(CarDtcCompleteness.COMPLETE, item.completeness)

        assertEquals(1, report.freezeFrames.size)
        val ff = report.freezeFrames[0]
        assertEquals("7E8", ff.sourceId)
        assertEquals(0, ff.frameNumber)
        assertEquals("P0300", ff.causeCode)
        assertEquals(CarDtcKind.STORED, ff.causeKind)
        assertEquals("7E8", ff.causeSourceId)
        assertEquals(2, ff.readings.size)
        assertEquals(CarFreezeSignalKind.COOLANT_C, ff.readings[0].signal)
        assertEquals(105.0, ff.readings[0].value, 0.0)
        assertEquals(CarFreezeSignalKind.SPEED_KMH, ff.readings[1].signal)
        assertEquals(60.0, ff.readings[1].value, 0.0)
        assertEquals(1, ff.undecodableCount)
        assertEquals(0, ff.unreadCount)
        assertEquals(2, ff.omittedByProjectionCount)
        assertFalse(ff.contentsUnknown)
    }

    @Test
    fun handlesNullAndCleanReport() {
        val repo = DefaultCarDtcRepository()
        val api = CarDiagnosticsHostApiImpl(repo)

        val message = CarDtcReportMessage(
            schemaVersion = 1,
            reportSequence = 1,
            connectionEpoch = 1,
            phase = CarDtcScanPhaseMessage.IDLE,
            verdict = CarDtcVerdictMessage.COMPLETE_CLEAN,
            coverageComplete = true,
            milOn = null,
            totalCodes = null,
            freezeFrameReadIncomplete = false,
            items = emptyList(),
            freezeFrames = emptyList(),
        )

        api.publishDtcReport(message)

        val state = repo.state.value as CarDtcState.Current
        val report = state.report

        assertEquals(CarDtcScanPhase.IDLE, report.phase)
        assertEquals(CarDtcVerdict.COMPLETE_CLEAN, report.verdict)
        assertTrue(report.coverageComplete)
        assertNull(report.milOn)
        assertNull(report.totalCodes)
        assertFalse(report.freezeFrameReadIncomplete)
        assertTrue(report.items.isEmpty())
        assertTrue(report.freezeFrames.isEmpty())
    }

    @Test
    fun producerReattachResetsRepositorySoLowerSequenceIsAccepted() {
        val repo = DefaultCarDtcRepository()
        val firstApi = CarDiagnosticsHostApiImpl(repo)

        // First producer sends up to sequence 50
        val msg50 = CarDtcReportMessage(
            schemaVersion = 1,
            reportSequence = 50,
            connectionEpoch = 1,
            phase = CarDtcScanPhaseMessage.IDLE,
            verdict = CarDtcVerdictMessage.NOT_SCANNED,
            coverageComplete = false,
            milOn = null,
            totalCodes = null,
            freezeFrameReadIncomplete = false,
            items = emptyList(),
            freezeFrames = emptyList(),
        )
        firstApi.publishDtcReport(msg50)
        assertEquals(50L, (repo.state.value as CarDtcState.Current).report.reportSequence)

        // New producer attaches (e.g. FlutterEngine restart on same connection)
        val secondApi = CarDiagnosticsHostApiImpl(repo)

        // Second producer starts sequence at 1
        val msg1 = CarDtcReportMessage(
            schemaVersion = 1,
            reportSequence = 1,
            connectionEpoch = 1,
            phase = CarDtcScanPhaseMessage.IDLE,
            verdict = CarDtcVerdictMessage.COMPLETE_CLEAN,
            coverageComplete = true,
            milOn = false,
            totalCodes = 0,
            freezeFrameReadIncomplete = false,
            items = emptyList(),
            freezeFrames = emptyList(),
        )
        secondApi.publishDtcReport(msg1)
        assertEquals(1L, (repo.state.value as CarDtcState.Current).report.reportSequence)
        assertEquals(CarDtcVerdict.COMPLETE_CLEAN, (repo.state.value as CarDtcState.Current).report.verdict)
    }
}

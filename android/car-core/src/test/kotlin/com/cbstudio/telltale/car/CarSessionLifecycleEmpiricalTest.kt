package com.cbstudio.telltale.car

import androidx.car.app.testing.TestCarContext
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Empirical Adversarial Challenger Test for Defect R4:
 * Session lifecycle stop/start DTC state restoration, epoch invalidation, and destroy semantics.
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarSessionLifecycleEmpiricalTest {

    private lateinit var carContext: TestCarContext
    private lateinit var testScope: TestScope
    private var virtualTimeMs: Long = 1_000L

    private class NoopSpeedGateway : CarHardwareSpeedGateway {
        override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {}
        override fun stopListening() {}
    }

    @Before
    fun setUp() {
        carContext = TestCarContext.createCarContext(ApplicationProvider.getApplicationContext())
        testScope = TestScope()
        virtualTimeMs = 1_000L
    }

    private fun sampleReport(
        sequence: Long = 1,
        epoch: Long = 1,
    ) = CarDtcReport(
        schemaVersion = 1,
        reportSequence = sequence,
        connectionEpoch = epoch,
        phase = CarDtcScanPhase.IDLE,
        verdict = CarDtcVerdict.COMPLETE_CLEAN,
        coverageComplete = true,
        milOn = false,
        totalCodes = 0,
        freezeFrameReadIncomplete = false,
        items = emptyList(),
        freezeFrames = emptyList(),
    )

    private fun frameInput(
        sequence: Long = 1,
        epoch: Long = 1,
        speed: Double = 0.0,
    ) = CarTelemetryFrameInput(
        schemaVersion = 2,
        sequence = sequence,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh = CarSignalInput(CarSignalStatus.LIVE, speed),
        rpm = CarSignalInput(CarSignalStatus.LIVE, 800.0),
        coolantC = CarSignalInput(CarSignalStatus.LIVE, 90.0),
        intakeAirC = CarSignalInput(CarSignalStatus.LIVE, 25.0),
        controlModuleVoltageV = CarSignalInput(CarSignalStatus.LIVE, 14.0),
        mapKpa = CarSignalInput(CarSignalStatus.LIVE, 35.0),
        diagnosticsAvailable = true,
        milOn = false,
        dtcCount = 0,
    )

    @Test
    fun empirical_multipleStartStopCycles_reliablyRestoresDtcStateWithoutManualSubmit() = testScope.runTest {
        val dtcRepo = DefaultCarDtcRepository()
        val originalReport = sampleReport(sequence = 42, epoch = 7)
        dtcRepo.submit(originalReport)
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
            dtcRepository = dtcRepo,
        )
        telemRepo.submit(frameInput(sequence = 1, epoch = 7))

        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            hostSpeedGateway = NoopSpeedGateway(),
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        // Initial start
        runtime.start()
        assertTrue(runtime.isStarted)
        val initialRestored = dtcRepo.state.value
        assertTrue("Initial start must have Current state", initialRestored is CarDtcState.Current)
        assertEquals(42L, (initialRestored as CarDtcState.Current).report.reportSequence)

        // Perform 10 consecutive stop -> start cycles without ANY manual dtcRepo.submit()
        for (cycle in 1..10) {
            runtime.stop()
            assertFalse("Cycle $cycle: runtime must not be started", runtime.isStarted)
            assertEquals("Cycle $cycle: dtcRepo state must be Awaiting during stop", CarDtcState.Awaiting, dtcRepo.state.value)
            assertEquals("Cycle $cycle: snapshot must still be preserved in latestValidReport", originalReport, dtcRepo.latestValidReport)

            runtime.start()
            assertTrue("Cycle $cycle: runtime must be started", runtime.isStarted)
            val stateAfterResume = dtcRepo.state.value
            assertTrue("Cycle $cycle: dtc state must be Current after resume without manual submit", stateAfterResume is CarDtcState.Current)
            assertEquals("Cycle $cycle: report must match originalReport exactly", originalReport, (stateAfterResume as CarDtcState.Current).report)
        }
    }

    @Test
    fun empirical_epochChangeDuringStop_strictlySuppressesOldSnapshotOnStart() = testScope.runTest {
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(sampleReport(sequence = 1, epoch = 10))

        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
            dtcRepository = dtcRepo,
        )
        telemRepo.submit(frameInput(sequence = 1, epoch = 10))

        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            hostSpeedGateway = NoopSpeedGateway(),
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        // Session backgrounded
        runtime.stop()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)

        // New vehicle connects: telemetry epoch bumps to 11
        telemRepo.submit(frameInput(sequence = 1, epoch = 11))

        // Snapshot must have been purged immediately by telemetry epoch bump
        assertNull("DTC snapshot must be purged when telemetry epoch bumped", dtcRepo.latestValidReport)

        // Session brought back to foreground
        runtime.start()
        assertEquals("Resumed session with bumped epoch must NEVER restore old epoch 10 snapshot", CarDtcState.Awaiting, dtcRepo.state.value)

        // New scan completes on epoch 11
        val newReport = sampleReport(sequence = 1, epoch = 11)
        dtcRepo.submit(newReport)
        assertTrue(dtcRepo.state.value is CarDtcState.Current)
        assertEquals(11L, (dtcRepo.state.value as CarDtcState.Current).report.connectionEpoch)

        // Stop and resume on epoch 11 must now restore the epoch 11 report
        runtime.stop()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
        runtime.start()
        assertEquals(CarDtcState.Current(newReport), dtcRepo.state.value)
    }

    @Test
    fun empirical_destroyPermanentlyClearsSnapshot() = testScope.runTest {
        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        telemRepo.submit(frameInput(sequence = 1, epoch = 5))
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(sampleReport(sequence = 1, epoch = 5))

        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            hostSpeedGateway = NoopSpeedGateway(),
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        // Destroy session permanently
        runtime.destroy()
        assertFalse(runtime.isStarted)
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
        assertNull("Snapshot must be null after destroy()", dtcRepo.latestValidReport)

        // Re-starting runtime must NOT restore destroyed snapshot
        runtime.start()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
        assertFalse("replaySnapshot must return false after destroy", dtcRepo.replaySnapshot(5))
    }

    @Test
    fun empirical_mismatchedExpectedEpochInReplay_permanentlyPurgesSnapshot() {
        val dtcRepo = DefaultCarDtcRepository()
        val report = sampleReport(sequence = 1, epoch = 3)
        dtcRepo.submit(report)
        dtcRepo.reset(clearSnapshot = false)

        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
        assertEquals(report, dtcRepo.latestValidReport)

        // Replay with mismatching epoch (e.g. 4 instead of 3)
        val success = dtcRepo.replaySnapshot(expectedEpoch = 4)
        assertFalse("Replay with mismatched epoch must return false", success)
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
        assertNull("Snapshot must be permanently purged on epoch mismatch", dtcRepo.latestValidReport)

        // Even with expectedEpoch = 3, subsequent replay must fail because snapshot was purged
        assertFalse("Subsequent replay must also fail", dtcRepo.replaySnapshot(expectedEpoch = 3))
    }
}

package com.cbstudio.telltale.car

import android.content.Intent
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedPermissionCoordinator
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
import com.cbstudio.telltale.car.health.CarAlertCoordinator
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarSessionRuntimeTest {

    private lateinit var carContext: TestCarContext
    private lateinit var testScope: TestScope
    private var virtualTimeMs: Long = 1_000L

    private class FakeCarHardwareSpeedGateway : CarHardwareSpeedGateway {
        var callback: ((CarHostSpeedSample) -> Unit)? = null
        var isListening = false
        var startListeningCount = 0

        override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
            callback = onSpeedAvailable
            isListening = true
            startListeningCount++
        }

        override fun stopListening() {
            callback = null
            isListening = false
        }
    }

    @Before
    fun setUp() {
        val dispatcher = StandardTestDispatcher()
        testScope = TestScope(dispatcher)
        virtualTimeMs = 1_000L
        carContext = TestCarContext.createCarContext(ApplicationProvider.getApplicationContext())
        val packageInfo = carContext.packageManager.getPackageInfo(carContext.packageName, 0).apply {
            requestedPermissions = arrayOf(
                CarHostSpeedPermissionCoordinator.PERMISSION_CAR_SPEED_PROJECTED,
            )
        }
        org.robolectric.Shadows.shadowOf(carContext.packageManager).installPackage(packageInfo)
    }

    @Test
    fun startRegistersGatewayAndPropagatesSpeedUpdates() = testScope.runTest {
        val fakeGateway = FakeCarHardwareSpeedGateway()
        val speedRepo = CarHostSpeedRepository(maxAgeMs = 3_000L)
        val telemetryRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemetryRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemetryRepo,
            hostSpeedGateway = fakeGateway,
            hostSpeedRepository = speedRepo,
            alertCoordinator = alertCoord,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        assertFalse(runtime.isStarted)
        assertFalse(fakeGateway.isListening)

        runtime.start()
        assertTrue(runtime.isStarted)
        assertTrue(fakeGateway.isListening)

        // Gateway produces sample
        val sample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = 12f,
            displaySpeedMetersPerSecond = 12.5f,
            receivedAtElapsedMs = virtualTimeMs,
        )
        fakeGateway.callback?.invoke(sample)
        runCurrent()

        assertEquals(sample, speedRepo.sample.value)

        // Stop stops gateway and resets speedRepo to avoid leaking old sample across visibility
        runtime.stop()
        assertFalse(runtime.isStarted)
        assertFalse(fakeGateway.isListening)
        assertEquals(CarHostSpeedSample.INITIAL, speedRepo.sample.value)
    }

    @Test
    fun startResetsSpeedRepositoryBeforeListening() = testScope.runTest {
        val fakeGateway = FakeCarHardwareSpeedGateway()
        val speedRepo = CarHostSpeedRepository()
        speedRepo.updateSample(CarHostSpeedSample(status = CarHostSpeedStatus.LIVE, displaySpeedMetersPerSecond = 0f))

        val runtime = CarSessionRuntime(
            carContext = carContext,
            hostSpeedGateway = fakeGateway,
            hostSpeedRepository = speedRepo,
            coroutineScope = backgroundScope,
        )

        // Before start, speedRepo has old 0
        assertEquals(0f, speedRepo.sample.value.displaySpeedMetersPerSecond)

        // Upon start, speedRepo is reset immediately so stale 0 is cleared
        runtime.start()
        assertEquals(CarHostSpeedSample.INITIAL, speedRepo.sample.value)

        runtime.destroy()
    }

    @Test
    fun retryHostSpeedRestartsGatewayListening() = testScope.runTest {
        val fakeGateway = FakeCarHardwareSpeedGateway()
        val speedRepo = CarHostSpeedRepository()
        val runtime = CarSessionRuntime(
            carContext = carContext,
            hostSpeedGateway = fakeGateway,
            hostSpeedRepository = speedRepo,
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertTrue(fakeGateway.isListening)

        // Gateway reports permission denied
        fakeGateway.callback?.invoke(CarHostSpeedSample(status = CarHostSpeedStatus.PERMISSION_DENIED))
        assertEquals(CarHostSpeedStatus.PERMISSION_DENIED, speedRepo.sample.value.status)

        // User grants permission and triggers retryHostSpeed
        runtime.retryHostSpeed()
        assertTrue(fakeGateway.isListening)

        // New sample received
        fakeGateway.callback?.invoke(CarHostSpeedSample(status = CarHostSpeedStatus.LIVE, displaySpeedMetersPerSecond = 15f))
        assertEquals(CarHostSpeedStatus.LIVE, speedRepo.sample.value.status)

        runtime.destroy()
    }

    @Test
    fun permissionGrantRetriesGatewayExactlyOnce() = testScope.runTest {
        val fakeGateway = FakeCarHardwareSpeedGateway()
        val speedRepo = CarHostSpeedRepository()
        val runtime = CarSessionRuntime(
            carContext = carContext,
            hostSpeedGateway = fakeGateway,
            hostSpeedRepository = speedRepo,
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertEquals(1, fakeGateway.startListeningCount)

        // Request permissions and simulate user grant
        runtime.permissionCoordinator.requestPermissions(carContext)
        val perms = CarHostSpeedPermissionCoordinator.resolveRequiredPermissions(carContext)
        val info = carContext.lastPermissionRequestInfo
        info?.listener?.onRequestPermissionsResult(perms, emptyList<String>())

        // Exactly one retry invocation happened upon grant
        assertEquals(2, fakeGateway.startListeningCount)
        assertTrue(fakeGateway.isListening)

        runtime.destroy()
    }

    @Test
    fun permissionGrantWhileRuntimeStoppedDoesNotRegisterListener() = testScope.runTest {
        val fakeGateway = FakeCarHardwareSpeedGateway()
        val speedRepo = CarHostSpeedRepository()
        val runtime = CarSessionRuntime(
            carContext = carContext,
            hostSpeedGateway = fakeGateway,
            hostSpeedRepository = speedRepo,
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertTrue(fakeGateway.isListening)
        assertEquals(1, fakeGateway.startListeningCount)

        // Request permissions while started
        runtime.permissionCoordinator.requestPermissions(carContext)

        // Session stops before permission callback arrives
        runtime.stop()
        assertFalse(runtime.isStarted)
        assertFalse(fakeGateway.isListening)

        // Permission result returns after STOP
        val perms = CarHostSpeedPermissionCoordinator.resolveRequiredPermissions(carContext)
        val info = carContext.lastPermissionRequestInfo
        info?.listener?.onRequestPermissionsResult(perms, emptyList<String>())

        // Listener must NOT be registered because runtime is stopped
        assertFalse(fakeGateway.isListening)
        assertEquals(1, fakeGateway.startListeningCount)

        runtime.destroy()
    }

    @Test
    fun freshnessJobPeriodicallyEvictsStaleSpeedSamples() = testScope.runTest {
        val fakeGateway = FakeCarHardwareSpeedGateway()
        val speedRepo = CarHostSpeedRepository(maxAgeMs = 3_000L)
        val telemetryRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )

        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemetryRepo,
            hostSpeedGateway = fakeGateway,
            hostSpeedRepository = speedRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        runtime.start()
        runCurrent()

        // Push live sample at t = 1000ms
        speedRepo.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 20f,
                displaySpeedMetersPerSecond = 20f,
                receivedAtElapsedMs = 1_000L,
            ),
        )

        // Advance 2 seconds (t = 3000ms, age = 2000ms < 3000ms)
        virtualTimeMs = 3_000L
        advanceTimeBy(2_000L)
        runCurrent()
        assertEquals(CarHostSpeedStatus.LIVE, speedRepo.sample.value.status)

        // Advance past 3000ms age (t = 5000ms, age = 4000ms > 3000ms)
        virtualTimeMs = 5_000L
        advanceTimeBy(2_000L)
        runCurrent()
        assertEquals(CarHostSpeedStatus.STALE, speedRepo.sample.value.status)

        runtime.destroy()
    }

    @Test
    fun gatewaySampleEmittedWhileRuntimeStoppedDoesNotUpdateRepository() = testScope.runTest {
        var capturedCallback: ((CarHostSpeedSample) -> Unit)? = null
        val gateway = object : CarHardwareSpeedGateway {
            override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
                capturedCallback = onSpeedAvailable
            }
            override fun stopListening() {}
        }
        val speedRepo = CarHostSpeedRepository()
        val telemetryRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemetryRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )
        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemetryRepo,
            hostSpeedGateway = gateway,
            hostSpeedRepository = speedRepo,
            alertCoordinator = alertCoord,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertTrue(runtime.isStarted)

        runtime.stop()
        assertFalse(runtime.isStarted)
        assertEquals(CarHostSpeedSample.INITIAL, speedRepo.sample.value)

        // Gateway produces sample asynchronously after runtime is stopped
        capturedCallback?.invoke(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 25f,
                displaySpeedMetersPerSecond = 25f,
                receivedAtElapsedMs = virtualTimeMs,
            ),
        )

        // Must remain INITIAL and not leak live sample while stopped
        assertEquals(CarHostSpeedSample.INITIAL, speedRepo.sample.value)

        runtime.destroy()
    }

    @Test
    fun gatewaySampleFromPreviousGenerationAfterRestartDoesNotOverwriteNewSample() = testScope.runTest {
        val callbacks = mutableListOf<(CarHostSpeedSample) -> Unit>()
        val gateway = object : CarHardwareSpeedGateway {
            override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
                callbacks.add(onSpeedAvailable)
            }
            override fun stopListening() {}
        }
        val speedRepo = CarHostSpeedRepository()
        val telemetryRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemetryRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )
        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemetryRepo,
            hostSpeedGateway = gateway,
            hostSpeedRepository = speedRepo,
            alertCoordinator = alertCoord,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        // 1. Start generation 1 (callback A)
        runtime.start()
        assertEquals(1, callbacks.size)
        val callbackA = callbacks[0]

        // 2. Stop and restart -> generation 2 (callback B)
        runtime.stop()
        runtime.start()
        assertEquals(2, callbacks.size)
        val callbackB = callbacks[1]

        // 3. Callback B delivers fresh 25 m/s sample
        callbackB.invoke(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 25f,
                displaySpeedMetersPerSecond = 25f,
                receivedAtElapsedMs = virtualTimeMs,
            ),
        )
        assertEquals(25f, speedRepo.sample.value.displaySpeedMetersPerSecond)

        // 4. Stale callback A from generation 1 arrives late with 0 m/s
        callbackA.invoke(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 0f,
                displaySpeedMetersPerSecond = 0f,
                receivedAtElapsedMs = virtualTimeMs,
            ),
        )

        // Must remain 25 m/s, NOT overwritten by generation 1 callback
        assertEquals(25f, speedRepo.sample.value.displaySpeedMetersPerSecond)

        runtime.destroy()
    }

    @Test
    fun gatewaySampleFromPreviousGenerationAfterRetryDoesNotOverwriteNewSample() = testScope.runTest {
        val callbacks = mutableListOf<(CarHostSpeedSample) -> Unit>()
        val gateway = object : CarHardwareSpeedGateway {
            override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
                callbacks.add(onSpeedAvailable)
            }
            override fun stopListening() {}
        }
        val speedRepo = CarHostSpeedRepository()
        val telemetryRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemetryRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )
        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemetryRepo,
            hostSpeedGateway = gateway,
            hostSpeedRepository = speedRepo,
            alertCoordinator = alertCoord,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        // 1. Start generation 1
        runtime.start()
        assertEquals(1, callbacks.size)
        val callbackA = callbacks[0]

        // 2. Retry while remaining started -> generation 2
        runtime.retryHostSpeed()
        assertTrue(runtime.isStarted)
        assertEquals(2, callbacks.size)
        val callbackB = callbacks[1]

        // 3. Callback B delivers fresh 30 m/s sample
        callbackB.invoke(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 30f,
                displaySpeedMetersPerSecond = 30f,
                receivedAtElapsedMs = virtualTimeMs,
            ),
        )
        assertEquals(30f, speedRepo.sample.value.displaySpeedMetersPerSecond)

        // 4. Stale callback A from before retry arrives late with 0 m/s
        callbackA.invoke(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 0f,
                displaySpeedMetersPerSecond = 0f,
                receivedAtElapsedMs = virtualTimeMs,
            ),
        )

        // Must remain 30 m/s, NOT overwritten by pre-retry callback
        assertEquals(30f, speedRepo.sample.value.displaySpeedMetersPerSecond)

        runtime.destroy()
    }

    @Test
    fun gatewaySampleAfterDestroyIsIgnored() = testScope.runTest {
        var capturedCallback: ((CarHostSpeedSample) -> Unit)? = null
        val gateway = object : CarHardwareSpeedGateway {
            override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
                capturedCallback = onSpeedAvailable
            }
            override fun stopListening() {}
        }
        val speedRepo = CarHostSpeedRepository()
        val telemetryRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemetryRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )
        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemetryRepo,
            hostSpeedGateway = gateway,
            hostSpeedRepository = speedRepo,
            alertCoordinator = alertCoord,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        runtime.start()
        runtime.destroy()
        assertFalse(runtime.isStarted)

        capturedCallback?.invoke(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 20f,
                displaySpeedMetersPerSecond = 20f,
                receivedAtElapsedMs = virtualTimeMs,
            ),
        )

        assertEquals(CarHostSpeedSample.INITIAL, speedRepo.sample.value)
    }

    private fun sampleReport(sequence: Long = 1, epoch: Long = 1) = CarDtcReport(
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
        schemaVersion = 1,
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
    fun sessionRuntime_stopAndStart_seamlesslyRestoresDtcStateWithoutManualSubmit() = testScope.runTest {
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(sampleReport(sequence = 1, epoch = 1))
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        val runtime = CarSessionRuntime(
            carContext = carContext,
            dtcRepository = dtcRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )

        runtime.start()
        assertTrue(runtime.isStarted)

        // 1. stop() resets dtcRepository to Awaiting while preserving snapshot
        runtime.stop()
        assertFalse(runtime.isStarted)
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)

        // 2. start() seamlessly restores DTC state WITHOUT manual submit (R4)
        runtime.start()
        assertTrue(runtime.isStarted)
        val restoredState = dtcRepo.state.value
        assertTrue("Expected Current state on restart, was $restoredState", restoredState is CarDtcState.Current)
        assertEquals(1L, (restoredState as CarDtcState.Current).report.connectionEpoch)

        // 3. destroy() resets dtcRepository and permanently wipes snapshot
        runtime.destroy()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)

        // Re-starting after destroy must NOT restore anything
        runtime.start()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
    }

    @Test
    fun sessionRuntime_epochChangedDuringStop_strictlySuppressesOldDtcReportOnStart() = testScope.runTest {
        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))

        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(sampleReport(sequence = 1, epoch = 1))

        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            clock = { virtualTimeMs },
            coroutineScope = backgroundScope,
        )
        runtime.start()
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        // Backgrounded
        runtime.stop()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)

        // Telemetry epoch changes while stopped (reconnected to new session / car)
        telemRepo.submit(frameInput(sequence = 1, epoch = 2, speed = 0.0))

        // Resumed
        runtime.start()
        // Must NOT restore old epoch 1 report!
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
    }

    @Test
    fun telemetryRepository_epochBump_purgesDtcSnapshotImmediately() = testScope.runTest {
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(sampleReport(sequence = 1, epoch = 1))
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
            dtcRepository = dtcRepo,
        )
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        assertEquals(1L, dtcRepo.latestValidReport?.connectionEpoch)

        // Connection epoch bumps on telemetry
        telemRepo.submit(frameInput(sequence = 1, epoch = 2, speed = 0.0))

        // DTC snapshot and state must be purged immediately
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
        assertEquals(null, dtcRepo.latestValidReport)
    }
}

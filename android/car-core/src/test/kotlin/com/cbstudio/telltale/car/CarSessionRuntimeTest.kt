package com.cbstudio.telltale.car

import androidx.car.app.testing.TestCarContext
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedPermissionCoordinator
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
import com.cbstudio.telltale.car.health.CarAlertCoordinator
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
}

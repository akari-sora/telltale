package com.cbstudio.telltale.car

import androidx.car.app.ScreenManager
import androidx.car.app.model.ListTemplate
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.diagnostics.CarDtcCompleteness
import com.cbstudio.telltale.car.diagnostics.CarDtcItem
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.CarFreezeFrame
import com.cbstudio.telltale.car.diagnostics.CarFreezeReading
import com.cbstudio.telltale.car.diagnostics.CarFreezeSignalKind
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Empirical stress tests for Milestone M1 (Challenger 2):
 * - Async delay secondary checks under motion (forward, reverse, host speed).
 * - Immediate pop-back to CarHealthScreen and suppression of DTC items.
 * - Epoch session isolation and invalidation across CarDtcSummaryScreen, CarDtcDetailScreen,
 *   CarDtcRepository, and CarSessionRuntime.
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarDtcEmpiricalChallengeTest {

    private lateinit var carContext: TestCarContext
    private lateinit var testDispatcher: TestDispatcher

    @Before
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext(),
        )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)

    private fun frameInput(
        sequence: Long = 1,
        epoch: Long = 1,
        speed: Double = 0.0,
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
    ) = CarTelemetryFrameInput(
        schemaVersion = 1,
        sequence = sequence,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = phase,
        speedKmh = live(speed),
        rpm = live(800.0),
        coolantC = live(90.0),
        intakeAirC = live(25.0),
        controlModuleVoltageV = live(14.0),
        mapKpa = live(35.0),
        diagnosticsAvailable = true,
        milOn = true,
        dtcCount = 1,
    )

    private fun createDtcReport(
        sequence: Long = 1,
        epoch: Long = 1,
        items: List<CarDtcItem> = listOf(
            CarDtcItem(
                code = "P0300",
                kind = CarDtcKind.STORED,
                sourceId = "7E8",
                isManufacturerSpecific = false,
                completeness = CarDtcCompleteness.COMPLETE,
            ),
        ),
    ) = CarDtcReport(
        schemaVersion = 1,
        reportSequence = sequence,
        connectionEpoch = epoch,
        phase = CarDtcScanPhase.IDLE,
        verdict = if (items.isEmpty()) CarDtcVerdict.COMPLETE_CLEAN else CarDtcVerdict.FAULTS_FOUND,
        coverageComplete = true,
        milOn = items.isNotEmpty(),
        totalCodes = items.size.toLong(),
        freezeFrameReadIncomplete = false,
        items = items,
        freezeFrames = emptyList(),
    )

    private fun TestScope.createTelemetryRepo() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    // =========================================================================
    // SECTION 1: CarDtcSummaryScreen Async Delay Secondary Checks Under Motion
    // =========================================================================

    @Test
    fun summaryScreen_asyncReportArrivalWhileMovingForward_immediatelyPopsBackAndSuppressesItems() = runTest {
        val telemRepo = createTelemetryRepo()
        // Vehicle moving forward at 35 km/h
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 35.0))
        val dtcRepo = DefaultCarDtcRepository()

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val summaryScreen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(summaryScreen)
        val controller = ScreenController(summaryScreen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Async DTC report with fault codes arrives while vehicle is moving
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1))
        runCurrent()

        // 1. Must immediately pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() must return unavailable template without DTC items
        val template = summaryScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun summaryScreen_asyncReportArrivalWhileMovingInReverse_immediatelyPopsBackAndSuppressesItems() = runTest {
        val telemRepo = createTelemetryRepo()
        // Vehicle moving in reverse at -3.5 km/h (SAFE-02)
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = -3.5))
        val dtcRepo = DefaultCarDtcRepository()

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val summaryScreen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(summaryScreen)
        val controller = ScreenController(summaryScreen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Async report arrives
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1))
        runCurrent()

        // 1. Must pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() must fail safe
        val template = summaryScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun summaryScreen_asyncReportArrivalWhileHostSpeedMoving_immediatelyPopsBack() = runTest {
        val telemRepo = createTelemetryRepo()
        // OBD speed is 0.0 km/h, but Host Speed sensor detects motion (5.0 m/s)
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val hostSpeedRepo = CarHostSpeedRepository()
        hostSpeedRepo.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 5.0f,
                displaySpeedMetersPerSecond = 5.0f,
                receivedAtElapsedMs = 1_000L,
            ),
        )
        val dtcRepo = DefaultCarDtcRepository()

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val summaryScreen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            hostSpeedRepository = hostSpeedRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(summaryScreen)
        val controller = ScreenController(summaryScreen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Async report arrives
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1))
        runCurrent()

        // Must pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        val template = summaryScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    // =========================================================================
    // SECTION 2: CarDtcDetailScreen Async Delay Secondary Checks Under Motion
    // =========================================================================

    @Test
    fun detailScreen_asyncReportArrivalWhileMovingForward_immediatelyPopsBackAndSuppressesDetails() = runTest {
        val telemRepo = createTelemetryRepo()
        // Initially stationary
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0171",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1, items = listOf(item)))

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val detailScreen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(detailScreen)
        val controller = ScreenController(detailScreen)
        controller.moveToState(Lifecycle.State.RESUMED)
        assertEquals(detailScreen, screenManager.top)

        // Vehicle starts moving (speed = 25 km/h)
        telemRepo.submit(frameInput(sequence = 2, epoch = 1, speed = 25.0))

        // Simultaneously / concurrently, an updated async DTC report arrives
        dtcRepo.submit(createDtcReport(sequence = 2, epoch = 1, items = listOf(item)))
        runCurrent()

        // 1. Must pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() must return unavailable template without detail rows
        val template = detailScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun detailScreen_asyncReportArrivalWhileMovingInReverse_immediatelyPopsBack() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1, items = listOf(item)))

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val detailScreen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(detailScreen)
        val controller = ScreenController(detailScreen)
        controller.moveToState(Lifecycle.State.RESUMED)
        assertEquals(detailScreen, screenManager.top)

        // Vehicle shifts into reverse (-4.0 km/h)
        telemRepo.submit(frameInput(sequence = 2, epoch = 1, speed = -4.0))

        // New report arrives
        dtcRepo.submit(createDtcReport(sequence = 2, epoch = 1, items = listOf(item)))
        runCurrent()

        // Must pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        val template = detailScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun detailScreen_asyncReportArrivalWhileHostSpeedMoving_immediatelyPopsBack() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val hostSpeedRepo = CarHostSpeedRepository()
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1, items = listOf(item)))

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val detailScreen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            hostSpeedRepository = hostSpeedRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(detailScreen)
        val controller = ScreenController(detailScreen)
        controller.moveToState(Lifecycle.State.RESUMED)
        assertEquals(detailScreen, screenManager.top)

        // Host Speed reports reverse motion (display 0f, raw -1.5f)
        hostSpeedRepo.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = -1.5f,
                displaySpeedMetersPerSecond = 0.0f,
                receivedAtElapsedMs = 1_000L,
            ),
        )

        // Async report arrives
        dtcRepo.submit(createDtcReport(sequence = 2, epoch = 1, items = listOf(item)))
        runCurrent()

        assertEquals(healthScreen, screenManager.top)

        val template = detailScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    // =========================================================================
    // SECTION 3: Epoch Session Isolation and Reset
    // =========================================================================

    @Test
    fun sessionRuntime_stopResetsDtcRepositoryToAwaiting() = runTest {
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1))
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        val runtime = CarSessionRuntime(
            carContext = carContext,
            dtcRepository = dtcRepo,
            coroutineScope = backgroundScope,
        )
        runtime.start()
        assertTrue(runtime.isStarted)

        // stop() must reset dtcRepository to Awaiting
        runtime.stop()
        assertFalse(runtime.isStarted)
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
    }

    @Test
    fun telemetryRepository_onProducerAttachedResetsDtcRepositoryToAwaiting() = runTest {
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1))
        assertTrue(dtcRepo.state.value is CarDtcState.Current)

        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { 1_000L },
            dtcRepository = dtcRepo,
        )
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))

        // Producer re-attaches (e.g. Flutter engine restart)
        telemRepo.onProducerAttached()

        assertEquals(CarTelemetryState.Awaiting, telemRepo.state.value)
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)
    }

    @Test
    fun summaryScreen_epochMismatch_immediatelyPopsBackAndSuppressesOldEpochItems() = runTest {
        val telemRepo = createTelemetryRepo()
        // Epoch 1 telemetry
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        // Epoch 1 DTC report
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1))

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val summaryScreen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(summaryScreen)
        val controller = ScreenController(summaryScreen)
        controller.moveToState(Lifecycle.State.RESUMED)
        assertEquals(summaryScreen, screenManager.top)

        // Telemetry switches to Epoch 2 (e.g. reconnected to different car)
        telemRepo.submit(frameInput(sequence = 1, epoch = 2, speed = 0.0))
        runCurrent()

        // 1. Must pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() must NOT render items from Epoch 1
        val template = summaryScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun detailScreen_epochMismatch_immediatelyPopsBackAndSuppressesOldEpochDetails() = runTest {
        val telemRepo = createTelemetryRepo()
        // Epoch 1 telemetry
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        // Epoch 1 DTC report
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 1, items = listOf(item)))

        val healthScreen = CarHealthScreen(carContext, telemetryRepository = telemRepo, dtcRepository = dtcRepo)
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val detailScreen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(detailScreen)
        val controller = ScreenController(detailScreen)
        controller.moveToState(Lifecycle.State.RESUMED)
        assertEquals(detailScreen, screenManager.top)

        // Telemetry switches to Epoch 2
        telemRepo.submit(frameInput(sequence = 1, epoch = 2, speed = 0.0))
        runCurrent()

        // 1. Must pop back to health screen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() must NOT render old item
        val template = detailScreen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun dtcRepository_dropsOlderEpochReportsAndAllowsNewEpochAfterReset() {
        val dtcRepo = DefaultCarDtcRepository()

        // Submit report with epoch 5, sequence 1
        val reportEpoch5 = createDtcReport(sequence = 1, epoch = 5)
        dtcRepo.submit(reportEpoch5)
        assertEquals(reportEpoch5, (dtcRepo.state.value as CarDtcState.Current).report)

        // Stale report with epoch 4 arrives -> must be dropped
        val reportEpoch4 = createDtcReport(sequence = 99, epoch = 4)
        dtcRepo.submit(reportEpoch4)
        assertEquals(reportEpoch5, (dtcRepo.state.value as CarDtcState.Current).report)

        // Stale report with same epoch 5 but older sequence 1 -> must be dropped
        dtcRepo.submit(createDtcReport(sequence = 1, epoch = 5))
        assertEquals(reportEpoch5, (dtcRepo.state.value as CarDtcState.Current).report)

        // Reset repository
        dtcRepo.reset()
        assertEquals(CarDtcState.Awaiting, dtcRepo.state.value)

        // After reset, fresh connection starting from epoch 0 must be accepted
        val reportEpoch0 = createDtcReport(sequence = 1, epoch = 0)
        dtcRepo.submit(reportEpoch0)
        assertEquals(reportEpoch0, (dtcRepo.state.value as CarDtcState.Current).report)
    }
}

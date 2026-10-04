package com.cbstudio.telltale.car

import androidx.car.app.model.Action
import androidx.car.app.model.PaneTemplate
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarHomeScreenTest {

    private lateinit var carContext: TestCarContext
    private lateinit var testDispatcher: TestDispatcher

    @Before
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)
        carContext =
            TestCarContext.createCarContext(
                ApplicationProvider.getApplicationContext(),
            )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)
    private fun stale() = CarSignalInput(CarSignalStatus.STALE, null)
    private fun unavailable() = CarSignalInput(CarSignalStatus.UNAVAILABLE, null)

    private fun frameInput(
        schemaVersion: Long = 1,
        sequence: Long = 1,
        connectionEpoch: Long = 1,
        lifecycleEpoch: Long = 0,
        producedAtMonotonicUs: Long = 1_000,
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh: CarSignalInput = live(42.0),
        rpm: CarSignalInput = live(1800.0),
        coolantC: CarSignalInput = live(90.0),
        intakeAirC: CarSignalInput = live(25.0),
        controlModuleVoltageV: CarSignalInput = live(14.1),
        mapKpa: CarSignalInput = live(35.0),
        diagnosticsAvailable: Boolean = false,
        milOn: Boolean? = null,
        dtcCount: Long? = null,
    ) = CarTelemetryFrameInput(
        schemaVersion = schemaVersion,
        sequence = sequence,
        connectionEpoch = connectionEpoch,
        lifecycleEpoch = lifecycleEpoch,
        producedAtMonotonicUs = producedAtMonotonicUs,
        connectionPhase = phase,
        speedKmh = speedKmh,
        rpm = rpm,
        coolantC = coolantC,
        intakeAirC = intakeAirC,
        controlModuleVoltageV = controlModuleVoltageV,
        mapKpa = mapKpa,
        diagnosticsAvailable = diagnosticsAvailable,
        milOn = milOn,
        dtcCount = dtcCount,
    )

    private fun TestScope.createRepository() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    @Test
    fun homeScreen_returnsReadOnlyPaneTemplate() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate

        @Suppress("DEPRECATION")
        assertEquals("Telltale", template.title?.toString())
        assertEquals(Action.APP_ICON, template.headerAction)
        assertTrue("Pane must have no action buttons (read-only DDG compliance)", template.pane.actions.isEmpty())
        assertEquals(6, template.pane.rows.size)
    }

    @Test
    fun homeScreen_prioritizedMetricsOrdering() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rowTitles = template.pane.rows.map { it.title?.toString() }

        assertEquals(
            listOf("Speed", "RPM", "Coolant", "Module Voltage", "Boost", "Engine Load"),
            rowTitles,
        )
    }

    @Test
    fun homeScreen_dynamicRowLimit_fourRows() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rowTitles = template.pane.rows.map { it.title?.toString() }

        assertEquals(4, template.pane.rows.size)
        assertEquals(listOf("Speed", "RPM", "Coolant", "Module Voltage"), rowTitles)
    }

    @Test
    fun homeScreen_dynamicRowLimit_fiveRows() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 5 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rowTitles = template.pane.rows.map { it.title?.toString() }

        assertEquals(5, template.pane.rows.size)
        assertEquals(listOf("Speed", "RPM", "Coolant", "Module Voltage", "Boost"), rowTitles)
    }

    @Test
    fun homeScreen_dynamicRowLimit_sixRows() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        assertEquals(6, template.pane.rows.size)
    }

    @Test
    fun homeScreen_dynamicRowLimit_lowHostLimitsAllowed() = runTest {
        val repo = createRepository()

        // Host limit = 2 must return 2 rows (never clamp upwards to 4)
        val screenTwo = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 2 },
        )
        val controllerTwo = ScreenController(screenTwo)
        controllerTwo.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val templateTwo = screenTwo.onGetTemplate() as PaneTemplate
        assertEquals(2, screenTwo.resolveContentLimit())
        assertEquals(2, templateTwo.pane.rows.size)
        assertEquals(listOf("Speed", "RPM"), templateTwo.pane.rows.map { it.title?.toString() })

        // Host limit = 3 must return 3 rows
        val screenThree = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 3 },
        )
        assertEquals(3, screenThree.resolveContentLimit())
    }

    @Test
    fun homeScreen_dynamicRowLimit_boundaryClamping() = runTest {
        val repo = createRepository()

        // Test upper bound clamp (> 6 clamps to 6)
        val screenOver = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 10 },
        )
        assertEquals(6, screenOver.resolveContentLimit())

        // Non-positive limits must fall back to DEFAULT_PANE_LIMIT (4)
        val screenZero = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 0 },
        )
        assertEquals(4, screenZero.resolveContentLimit())

        val screenNeg = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { -1 },
        )
        assertEquals(4, screenNeg.resolveContentLimit())
    }

    @Test
    fun homeScreen_dynamicRowLimit_defaultFallbackWithoutProvider() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
        )
        // TestCarContext does not provide ConstraintManager, so it must safely fall back to DEFAULT_PANE_LIMIT (4)
        assertEquals(4, screen.resolveContentLimit())
    }

    @Test
    fun homeScreen_formatsLiveTelemetrySignals() = runTest {
        val repo = createRepository()
        repo.submit(
            frameInput(
                speedKmh = live(42.4),
                rpm = live(1800.0),
                coolantC = live(89.7),
                controlModuleVoltageV = live(14.12),
            ),
        )

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        assertEquals("42 km/h", rows[0].texts[0].toString())
        assertEquals("1800 RPM", rows[1].texts[0].toString())
        assertEquals("90 °C", rows[2].texts[0].toString())
        assertEquals("14.1 V", rows[3].texts[0].toString())
        // Boost & Load are missing in schema v1
        assertEquals("--", rows[4].texts[0].toString())
        assertEquals("--", rows[5].texts[0].toString())
    }

    @Test
    fun homeScreen_formatsZeroSpeedAsLiveZero() = runTest {
        val repo = createRepository()
        repo.submit(
            frameInput(
                speedKmh = live(0.0),
                rpm = live(750.0),
            ),
        )

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        assertEquals("0 km/h", template.pane.rows[0].texts[0].toString())
        assertEquals("750 RPM", template.pane.rows[1].texts[0].toString())
    }

    @Test
    fun homeScreen_missingSignalsDisplayDashesAndNeverZero() = runTest {
        val repo = createRepository()
        // Repository in initial Awaiting state: no frame accepted yet
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        for (row in template.pane.rows) {
            val text = row.texts[0].toString()
            assertEquals("Missing signal must display --", "--", text)
            assertNotEquals("Must never display fictitious 0", "0", text)
            assertNotEquals("Must never display fictitious 0 km/h", "0 km/h", text)
        }
    }

    @Test
    fun homeScreen_staleStateDisplaysStaleAcrossObservedSignalsAndMissingForAbsent() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(sequence = 1))

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Advance beyond staleness window (3,000ms default)
        advanceTimeBy(3_500)
        runCurrent()

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        // Rows 0..3 (Speed, RPM, Coolant, Module Voltage) were received in frameInput and are now stale
        for (i in 0..3) {
            val text = rows[i].texts[0].toString()
            assertEquals("Stale repository state must display Stale for observed signal", "Stale", text)
            assertNotEquals("Must never display fictitious 0", "0", text)
        }

        // Rows 4..5 (Boost, Engine Load) never existed in schema-v1, must remain missing (--)
        assertEquals("--", rows[4].texts[0].toString())
        assertEquals("--", rows[5].texts[0].toString())
        assertNotEquals("0", rows[4].texts[0].toString())
        assertNotEquals("0", rows[5].texts[0].toString())
    }

    @Test
    fun homeScreen_individualSignalStaleShowsStale() = runTest {
        val repo = createRepository()
        repo.submit(
            frameInput(
                speedKmh = stale(),
                rpm = live(2200.0),
                coolantC = unavailable(),
            ),
        )

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        assertEquals("Stale", rows[0].texts[0].toString())
        assertEquals("2200 RPM", rows[1].texts[0].toString())
        assertEquals("--", rows[2].texts[0].toString())
    }

    @Test
    fun homeScreen_boostAndLoadDisplayMissingAndNeverZero() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        // Boost and Load
        assertEquals("--", rows[4].texts[0].toString())
        assertEquals("--", rows[5].texts[0].toString())
        assertNotEquals("0", rows[4].texts[0].toString())
        assertNotEquals("0", rows[5].texts[0].toString())
    }

    @Test
    fun homeScreen_throttlesInvalidationToOneHz() = runTest {
        val repo = createRepository()
        var invalidationCount = 0

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
            clock = { testScheduler.currentTime },
            coroutineScope = backgroundScope,
        ).apply {
            onInvalidateListener = { invalidationCount++ }
        }

        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Initial render
        screen.onGetTemplate()
        assertEquals(0, invalidationCount)

        // First update at t = 100ms
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 1, speedKmh = live(10.0)))
        runCurrent()
        assertEquals("First update should invalidate immediately", 1, invalidationCount)

        // Rapid burst: update at t = 200ms (100ms after last invalidate)
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 2, speedKmh = live(20.0)))
        runCurrent()
        assertEquals("Burst update within 1000ms must be throttled", 1, invalidationCount)

        // Another update at t = 300ms
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 3, speedKmh = live(30.0)))
        runCurrent()
        assertEquals("Still within 1000ms window, pending refresh must not duplicate", 1, invalidationCount)

        // Advance past 1000ms throttle interval (from t=100 to t=1100)
        advanceTimeBy(800)
        runCurrent()
        assertEquals("Pending throttled refresh must execute after 1000ms window", 2, invalidationCount)

        // Verify the template rendered the latest speed (30 km/h)
        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        assertEquals("30 km/h", template.pane.rows[0].texts[0].toString())
    }

    @Test
    fun homeScreen_unchangedDataDoesNotTriggerInvalidate() = runTest {
        val repo = createRepository()
        var invalidationCount = 0

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
            clock = { testScheduler.currentTime },
            coroutineScope = backgroundScope,
        ).apply {
            onInvalidateListener = { invalidationCount++ }
        }

        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Advance to 100ms and submit frame 1 (Speed 50 km/h)
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 1, speedKmh = live(50.0)))
        runCurrent()
        assertEquals(1, invalidationCount)

        // Advance time past 1000ms
        advanceTimeBy(1_500)
        runCurrent()

        // Submit frame 2 with DIFFERENT sequence and timestamp, but IDENTICAL telemetry numbers
        repo.submit(frameInput(sequence = 2, producedAtMonotonicUs = 2000, speedKmh = live(50.0)))
        runCurrent()

        assertEquals("Identical display model must not trigger invalidate", 1, invalidationCount)
    }

    @Test
    fun homeScreen_stoppedLifecycleDoesNotTriggerInvalidateAndCancelsPending() = runTest {
        val repo = createRepository()
        var invalidationCount = 0

        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
            clock = { testScheduler.currentTime },
            coroutineScope = backgroundScope,
        ).apply {
            onInvalidateListener = { invalidationCount++ }
        }

        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // First update at t = 100
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 1, speedKmh = live(10.0)))
        runCurrent()
        assertEquals(1, invalidationCount)

        // Burst update scheduled at t = 200
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 2, speedKmh = live(20.0)))
        runCurrent()

        // App goes to STOPPED before pending refresh fires
        controller.moveToState(Lifecycle.State.CREATED)

        // Advance time beyond delay
        advanceTimeBy(2_000)
        runCurrent()

        assertEquals("No invalidation may fire while in STOPPED/CREATED state", 1, invalidationCount)
    }

    @Test
    fun homeScreen_onGetTemplateReadsCurrentRepositoryState() = runTest {
        val repo = createRepository()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
        )

        // Initially awaiting
        @Suppress("DEPRECATION")
        var template = screen.onGetTemplate() as PaneTemplate
        assertEquals("--", template.pane.rows[0].texts[0].toString())

        // Submit live frame
        repo.submit(frameInput(sequence = 1, speedKmh = live(70.0)))

        @Suppress("DEPRECATION")
        template = screen.onGetTemplate() as PaneTemplate
        assertEquals("70 km/h", template.pane.rows[0].texts[0].toString())
    }
}

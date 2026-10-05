package com.cbstudio.telltale.car

import androidx.car.app.model.Action
import androidx.car.app.model.PaneTemplate
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.health.CarAlertCoordinator
import com.cbstudio.telltale.car.health.CarAlertLevel
import com.cbstudio.telltale.car.health.CarAlertPhase
import com.cbstudio.telltale.car.health.CarAlertRepository
import com.cbstudio.telltale.car.health.CarAlertSnapshot
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
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarPowertrainScreenTest {

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
        rpm: Double = 1800.0,
        coolant: Double = 90.0,
        iat: Double = 25.0,
        map: Double = 35.0,
        voltage: Double = 14.1,
        speed: Double = 45.0,
    ) = CarTelemetryFrameInput(
        schemaVersion = 1,
        sequence = 1,
        connectionEpoch = 1,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh = live(speed),
        rpm = live(rpm),
        coolantC = live(coolant),
        intakeAirC = live(iat),
        controlModuleVoltageV = live(voltage),
        mapKpa = live(map),
        diagnosticsAvailable = true,
        milOn = false,
        dtcCount = 0,
    )

    private fun TestScope.createRepository() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    @Test
    fun powertrainScreen_returnsPaneTemplateWithBackAction() = runTest {
        val repo = createRepository()
        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        @Suppress("DEPRECATION")
        assertEquals("Powertrain", template.title?.toString())
        assertEquals(Action.BACK, template.headerAction)
        assertTrue("Powertrain screen has no action buttons", template.pane.actions.isEmpty())
    }

    @Test
    fun powertrainScreen_displaysSixPowertrainMetrics() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())

        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows
        assertEquals(6, rows.size)

        val titles = rows.map { it.title?.toString() }
        assertEquals(
            listOf("RPM", "Coolant", "Intake Air", "MAP", "Module Voltage", "Speed"),
            titles,
        )

        assertEquals("1800 RPM", rows[0].texts[0].toString())
        assertEquals("90 °C", rows[1].texts[0].toString())
        assertEquals("25 °C", rows[2].texts[0].toString())
        assertEquals("35 kPa", rows[3].texts[0].toString())
        assertEquals("14.1 V", rows[4].texts[0].toString())
        assertEquals("45 km/h", rows[5].texts[0].toString())
    }

    @Test
    fun powertrainScreen_dynamicLimitClamping() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())

        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            contentLimitProvider = { 4 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        assertEquals(4, template.pane.rows.size)
        assertEquals(
            listOf("RPM", "Coolant", "Intake Air", "MAP"),
            template.pane.rows.map { it.title?.toString() },
        )
    }

    @Test
    fun powertrainScreen_displaysInTemplateCoolantAlertWhenActive() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(coolant = 108.0))
        runCurrent()

        val alertRepo = CarAlertRepository()
        alertRepo.updateSnapshot(
            CarAlertSnapshot(
                level = CarAlertLevel.ATTENTION,
                coolant = CarAlertPhase.ACTIVE,
                connectionEpoch = 1L,
            ),
        )

        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            alertRepository = alertRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val coolantRow = template.pane.rows[1]
        assertEquals("Coolant", coolantRow.title?.toString())
        assertEquals("108 °C · High", coolantRow.texts[0].toString())
    }

    @Test
    fun powertrain_doesNotRenderAlertFromPreviousEpoch() = runTest {
        val repo = createRepository()
        // Current vehicle is Epoch 2
        repo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 2,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = live(45.0),
                rpm = live(1800.0),
                coolantC = live(108.0),
                intakeAirC = live(25.0),
                controlModuleVoltageV = live(14.1),
                mapKpa = live(35.0),
                diagnosticsAvailable = true,
                milOn = false,
                dtcCount = 0,
            ),
        )
        runCurrent()

        // Alert snapshot was retained from previous vehicle (Epoch 1)
        val alertRepo = CarAlertRepository()
        alertRepo.updateSnapshot(
            CarAlertSnapshot(
                level = CarAlertLevel.ATTENTION,
                coolant = CarAlertPhase.ACTIVE,
                connectionEpoch = 1L,
            ),
        )

        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            alertRepository = alertRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val coolantRow = template.pane.rows[1]
        assertEquals("Coolant", coolantRow.title?.toString())
        assertEquals("108 °C", coolantRow.texts[0].toString())
    }

    @Test
    fun powertrainScreen_alertTransitionTriggersImmediateRefresh() = runTest {
        var currentTime = 1_000L
        val repo = createRepository()
        repo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = live(45.0),
                rpm = live(1800.0),
                coolantC = live(108.0),
                intakeAirC = live(25.0),
                controlModuleVoltageV = live(14.1),
                mapKpa = live(35.0),
                diagnosticsAvailable = true,
                milOn = false,
                dtcCount = 0,
            ),
        )
        runCurrent()

        val alertCoord = CarAlertCoordinator(
            telemetryRepository = repo,
            clock = { currentTime },
            coroutineScope = backgroundScope,
        )

        var invalidateCount = 0
        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            alertRepository = alertCoord.repository,
            clock = { currentTime },
            contentLimitProvider = { 6 },
            coroutineScope = backgroundScope,
        )
        screen.onInvalidateListener = { invalidateCount++ }

        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)
        alertCoord.start()
        runCurrent()

        val initialInvalidates = invalidateCount

        // Advance 3001ms past hold threshold to trigger ACTIVE alert edge
        currentTime = 4_001L
        repo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 2,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 4_001_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = live(45.0),
                rpm = live(1800.0),
                coolantC = live(108.0),
                intakeAirC = live(25.0),
                controlModuleVoltageV = live(14.1),
                mapKpa = live(35.0),
                diagnosticsAvailable = true,
                milOn = false,
                dtcCount = 0,
            ),
        )
        runCurrent()

        assertEquals(CarAlertPhase.ACTIVE, alertCoord.repository.snapshot.value.coolant)
        assertTrue(invalidateCount > initialInvalidates)

        alertCoord.destroy()
    }

    @Test
    fun powertrainScreen_rapidSemanticEdgesTriggerImmediateRefresh() = runTest {
        val repo = createRepository()
        repo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = live(45.0),
                rpm = live(1800.0),
                coolantC = live(108.0),
                intakeAirC = live(25.0),
                controlModuleVoltageV = live(14.1),
                mapKpa = live(35.0),
                diagnosticsAvailable = true,
                milOn = false,
                dtcCount = 0,
            ),
        )
        runCurrent()

        val alertRepo = CarAlertRepository()
        var invalidateCount = 0
        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = repo,
            alertRepository = alertRepo,
            contentLimitProvider = { 6 },
            coroutineScope = backgroundScope,
        )
        screen.onInvalidateListener = { invalidateCount++ }

        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)
        runCurrent()

        val initialInvalidates = invalidateCount

        // Edge 1: NORMAL -> ACTIVE
        alertRepo.updateSnapshot(
            CarAlertSnapshot(level = CarAlertLevel.ATTENTION, coolant = CarAlertPhase.ACTIVE, connectionEpoch = 1L),
        )
        runCurrent()
        val afterEdge1 = invalidateCount
        assertTrue("Edge 1 (NORMAL -> ACTIVE) must trigger immediate refresh", afterEdge1 > initialInvalidates)

        // Edge 2: ACTIVE -> NORMAL
        alertRepo.updateSnapshot(
            CarAlertSnapshot(level = CarAlertLevel.NORMAL, coolant = CarAlertPhase.NORMAL, connectionEpoch = 1L),
        )
        runCurrent()
        val afterEdge2 = invalidateCount
        assertTrue("Edge 2 (ACTIVE -> NORMAL) must trigger immediate refresh", afterEdge2 > afterEdge1)
    }
}

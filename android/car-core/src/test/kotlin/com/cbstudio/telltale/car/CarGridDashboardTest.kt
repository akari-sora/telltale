package com.cbstudio.telltale.car

import android.graphics.drawable.Icon
import androidx.car.app.OnDoneCallback
import androidx.car.app.ScreenManager
import androidx.car.app.model.Action
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.diagnostics.CarDtcCompleteness
import com.cbstudio.telltale.car.diagnostics.CarDtcItem
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
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
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Template and refresh contracts; actual host layout still requires DHU/device acceptance. */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarGridDashboardTest {

    private lateinit var carContext: TestCarContext
    private val expectedTitles = listOf("Speed", "RPM", "Coolant", "Voltage")

    @Before
    fun setUp() {
        Dispatchers.setMain(StandardTestDispatcher())
        carContext = TestCarContext.createCarContext(ApplicationProvider.getApplicationContext())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)
    private fun unavailable() = CarSignalInput(CarSignalStatus.UNAVAILABLE, null)

    private fun frameInput(
        sequence: Long = 1,
        epoch: Long = 1,
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
        speed: CarSignalInput = live(42.4),
        rpm: CarSignalInput = live(1800.0),
        coolant: CarSignalInput = live(89.7),
        voltage: CarSignalInput = live(14.12),
    ) = CarTelemetryFrameInput(
        schemaVersion = 2,
        sequence = sequence,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = sequence * 1_000,
        connectionPhase = phase,
        speedKmh = speed,
        rpm = rpm,
        coolantC = coolant,
        intakeAirC = live(25.0),
        controlModuleVoltageV = voltage,
        mapKpa = live(35.0),
        engineLoadPct = live(67.5),
        diagnosticsAvailable = false,
        milOn = null,
        dtcCount = null,
    )

    private fun TestScope.createRepository() = CarTelemetryRepository(
        scope = backgroundScope,
        elapsedRealtimeMs = { testScheduler.currentTime },
    )

    private fun TestScope.graphicalScreen(
        repository: CarTelemetryRepository,
        gridLimit: () -> Int = { 4 },
        paneLimit: () -> Int = { 6 },
        alerts: CarAlertRepository = CarAlertRepository(),
        hostSpeed: CarHostSpeedRepository = CarHostSpeedRepository(),
        runtime: CarSessionRuntime? = null,
    ) = CarHomeScreen(
        carContext = carContext,
        repository = repository,
        contentLimitProvider = paneLimit,
        gridContentLimitProvider = gridLimit,
        graphicalDashboard = true,
        alertRepository = alerts,
        hostSpeedRepository = hostSpeed,
        sessionRuntime = runtime,
        clock = { testScheduler.currentTime },
        coroutineScope = backgroundScope,
    )

    private fun GridTemplate.items(): List<GridItem> = singleList!!.items.map { it as GridItem }

    @Test
    fun gridUsesFixedMetricTitlesAndNativeValuesWithClickableBitmapImages() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)

        val template = screen.onGetTemplate() as GridTemplate
        val items = template.items()
        assertEquals(expectedTitles, items.map { it.title?.toString() })
        assertEquals(listOf("42 km/h", "1800 RPM", "90 °C", "14.1 V"), items.map { it.text?.toString() })
        val rows = screen.buildDisplayModel(repo.state.value).rows
        assertEquals(listOf(42.0, 1800.0, 90.0, 14.1), rows.map { it.graphicValue })
        // The gauge numeral is the native reading without its unit, from the same formatting.
        assertEquals(listOf("42", "1800", "90", "14.1"), rows.map { it.graphicText })
        rows.zip(items).forEach { (row, item) ->
            assertTrue(item.text.toString().startsWith(row.graphicText!!))
            assertEquals(CarGaugeState.LIVE, row.gaugeState)
        }
        assertFalse(template.isLoading)
        assertEquals(Action.APP_ICON, template.header!!.startHeaderAction)
        assertEquals("Health", template.header!!.endHeaderActions.single().title?.toString())
        items.forEach { item ->
            assertFalse(item.isLoading)
            assertEquals(GridItem.IMAGE_TYPE_LARGE, item.imageType)
            assertNotNull(item.onClickDelegate)
            val icon = item.image!!.icon!!
            assertEquals(Icon.TYPE_BITMAP, icon.type)
            assertEquals(128, requireNotNull(icon.bitmap).width)
            assertEquals(128, requireNotNull(icon.bitmap).height)
        }
    }

    @Test
    fun carApi8HostsGetLargeGridItemsAndOlderOrUnknownHostsKeepTheDefaultSize() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        // Unknown host level (no handshake yet) keeps the default size.
        assertEquals(GridTemplate.ITEM_SIZE_SMALL, (graphicalScreen(repo).onGetTemplate() as GridTemplate).itemSize)
        carContext.updateHandshakeInfo(androidx.car.app.HandshakeInfo("test.host", 7))
        assertEquals(GridTemplate.ITEM_SIZE_SMALL, (graphicalScreen(repo).onGetTemplate() as GridTemplate).itemSize)
        carContext.updateHandshakeInfo(androidx.car.app.HandshakeInfo("test.host", 8))
        val screen = graphicalScreen(repo)
        val large = screen.onGetTemplate() as GridTemplate
        assertEquals(GridTemplate.ITEM_SIZE_LARGE, large.itemSize)
        // Same titles and count as before: the size does not change the refresh contract.
        assertEquals(expectedTitles, large.items().map { it.title?.toString() })
        repo.submit(frameInput(sequence = 2, speed = live(80.0)))
        assertEquals(GridTemplate.ITEM_SIZE_LARGE, (screen.onGetTemplate() as GridTemplate).itemSize)
    }

    @Test
    fun missingUnsupportedCorruptAndStaleSignalsKeepAllFourTilesWithoutGraphicValues() = runTest {
        val repo = createRepository()
        val screen = graphicalScreen(repo)

        fun assertUnavailableTiles(text: String) {
            val items = (screen.onGetTemplate() as GridTemplate).items()
            assertEquals(expectedTitles, items.map { it.title?.toString() })
            assertEquals(4, items.size)
            assertEquals(List(4) { text }, items.map { it.text?.toString() })
            screen.buildDisplayModel(repo.state.value).rows.forEach {
                assertNull(it.graphicValue)
                assertNull(it.graphicText)
                assertTrue(it.gaugeState != CarGaugeState.LIVE)
            }
        }
        fun states() = screen.buildDisplayModel(repo.state.value).rows.map { it.gaugeState }

        assertUnavailableTiles("--") // No frame was received.
        assertEquals(List(4) { CarGaugeState.NO_DATA }, states())
        val unavailableInputs = listOf(
            CarSignalInput(CarSignalStatus.UNSUPPORTED, 0.0),
            CarSignalInput(CarSignalStatus.UNAVAILABLE, 0.0),
            CarSignalInput(CarSignalStatus.LIVE, null),
            live(Double.NaN),
            live(Double.POSITIVE_INFINITY),
            live(Double.NEGATIVE_INFINITY),
        )
        unavailableInputs.forEachIndexed { index, signal ->
            repo.submit(frameInput(sequence = index + 1L, speed = signal, rpm = signal, coolant = signal, voltage = signal))
            assertUnavailableTiles("--")
            // Speed follows the OBD/host speed resolver, which reports no source rather than unsupported.
            val expected = if (signal.status == CarSignalStatus.UNSUPPORTED) {
                listOf(CarGaugeState.NO_DATA) + List(3) { CarGaugeState.UNSUPPORTED }
            } else {
                List(4) { CarGaugeState.NO_DATA }
            }
            assertEquals(expected, states())
        }
        val stale = CarSignalInput(CarSignalStatus.STALE, 0.0)
        repo.submit(frameInput(sequence = 10, speed = stale, rpm = stale, coolant = stale, voltage = stale))
        assertUnavailableTiles("Stale")
        assertEquals(List(4) { CarGaugeState.STALE }, states())
    }

    @Test
    fun expiredFrameRemovesGraphicValuesInsteadOfRetainingItsLastReading() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        assertTrue(screen.buildDisplayModel(repo.state.value).rows.all { it.graphicValue != null })
        runCurrent()
        advanceTimeBy(CarTelemetryRepository.DEFAULT_STALE_AFTER_MS + 1)
        runCurrent()

        assertTrue(repo.state.value is CarTelemetryState.Stale)
        assertEquals(List(4) { "Stale" }, (screen.onGetTemplate() as GridTemplate).items().map { it.text?.toString() })
        screen.buildDisplayModel(repo.state.value).rows.forEach {
            assertNull(it.graphicValue)
            assertNull(it.graphicText)
            assertEquals(CarGaugeState.STALE, it.gaugeState)
        }
    }

    @Test
    fun disconnectedProducerShowsStaleOrMissingAndDoesNotInventZero() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        screen.onGetTemplate()
        // The producer retains observed readings as STALE when its OBD connection closes.
        val stale = CarSignalInput(CarSignalStatus.STALE, 42.0)
        repo.submit(frameInput(sequence = 2, phase = CarConnectionPhase.DISCONNECTED, speed = stale, rpm = stale, coolant = stale, voltage = stale))
        val staleItems = (screen.onGetTemplate() as GridTemplate).items()
        assertEquals(expectedTitles, staleItems.map { it.title?.toString() })
        assertEquals(List(4) { "Stale" }, staleItems.map { it.text?.toString() })
        screen.buildDisplayModel(repo.state.value).rows.forEach { assertNull(it.graphicValue) }

        // A signal never observed by the producer is UNAVAILABLE after disconnect.
        repo.submit(frameInput(sequence = 3, phase = CarConnectionPhase.DISCONNECTED, speed = unavailable(), rpm = unavailable(), coolant = unavailable(), voltage = unavailable()))

        val items = (screen.onGetTemplate() as GridTemplate).items()
        assertEquals(expectedTitles, items.map { it.title?.toString() })
        assertEquals(List(4) { "--" }, items.map { it.text?.toString() })
        screen.buildDisplayModel(repo.state.value).rows.forEach { assertNull(it.graphicValue) }
    }

    @Test
    fun speedGraphicUsesTheSameHostFallbackAsTheNativeValue() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(speed = unavailable()))
        val hostSpeed = CarHostSpeedRepository().apply {
            updateSample(CarHostSpeedSample(status = CarHostSpeedStatus.LIVE, displaySpeedMetersPerSecond = 15f))
        }
        val screen = graphicalScreen(repo, hostSpeed = hostSpeed)

        assertEquals("54 km/h", (screen.onGetTemplate() as GridTemplate).items()[0].text?.toString())
        assertEquals(54.0, screen.buildDisplayModel(repo.state.value).rows[0].graphicValue!!, 0.0)
    }

    @Test
    fun gridRespectsSmallHostLimitsAndCapsLargerLimitsAtFour() = runTest {
        val repo = createRepository()
        listOf(1, 2, 6).forEach { limit ->
            val screen = graphicalScreen(repo, gridLimit = { limit })
            val items = (screen.onGetTemplate() as GridTemplate).items()
            assertEquals(minOf(limit, 4), items.size)
            assertEquals(expectedTitles.take(minOf(limit, 4)), items.map { it.title?.toString() })
        }
    }

    @Test
    fun gridConstraintIsResolvedOnceAndNeverUsesThePaneLimit() = runTest {
        val repo = createRepository()
        var gridCalls = 0
        var paneCalls = 0
        var hostLimit = 2
        val screen = graphicalScreen(repo, gridLimit = { gridCalls++; hostLimit }, paneLimit = { paneCalls++; 1 })
        assertEquals(1, gridCalls)

        hostLimit = 1
        repeat(3) { index ->
            repo.submit(frameInput(sequence = index + 1L, speed = live(index * 10.0)))
            assertEquals(expectedTitles.take(2), (screen.onGetTemplate() as GridTemplate).items().map { it.title?.toString() })
        }
        assertEquals(1, gridCalls)
        assertEquals(0, paneCalls)
    }

    @Test
    fun invalidOrUnavailableGridConstraintsFallBackToTheExistingNumericPane() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val providers = listOf<() -> Int>({ 0 }, { -1 }, { throw IllegalStateException("Host unavailable") })
        providers.forEach { provider ->
            val screen = graphicalScreen(repo, gridLimit = provider, paneLimit = { 6 })
            val template = screen.onGetTemplate() as PaneTemplate
            assertEquals(6, template.pane.rows.size)
            assertEquals("42 km/h", template.pane.rows[0].texts[0].toString())
            assertEquals(Action.APP_ICON, template.header!!.startHeaderAction)
            assertEquals("Health", template.header!!.endHeaderActions.single().title?.toString())
        }
    }

    @Test
    fun activeAndUnknownCoolantWarningsKeepTextAndGraphicStateConsistent() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(coolant = live(108.0)))
        val alerts = CarAlertRepository()
        val screen = graphicalScreen(repo, alerts = alerts)
        val normalImage = (screen.onGetTemplate() as GridTemplate).items()[2].image

        alerts.updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.ATTENTION, coolant = CarAlertPhase.ACTIVE, connectionEpoch = 1))
        val active = screen.buildDisplayModel(repo.state.value).rows[2]
        val activeItem = (screen.onGetTemplate() as GridTemplate).items()[2]
        assertTrue(active.warning)
        assertEquals(108.0, active.graphicValue!!, 0.0)
        assertEquals("108 °C · High", activeItem.text?.toString())
        assertEquals("108", active.graphicText)
        assertNotSame(normalImage, activeItem.image)

        repo.submit(frameInput(sequence = 2, coolant = CarSignalInput(CarSignalStatus.STALE, null)))
        alerts.updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.UNKNOWN, coolant = CarAlertPhase.UNKNOWN_AFTER_WARNING, connectionEpoch = 1))
        val unknown = screen.buildDisplayModel(repo.state.value).rows[2]
        assertTrue(unknown.warning)
        assertNull(unknown.graphicValue)
        assertNull(unknown.graphicText)
        assertEquals(CarGaugeState.STALE, unknown.gaugeState)
        assertEquals("Stale", (screen.onGetTemplate() as GridTemplate).items()[2].text?.toString())
    }

    @Test
    fun gridHeaderOpensHealthDirectlyWithoutAnIntermediateValuesPage() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        carContext.lifecycleOwner.registry.currentState = Lifecycle.State.RESUMED
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(screen)

        val healthAction = (screen.onGetTemplate() as GridTemplate).header!!.endHeaderActions.single()
        assertEquals("Health", healthAction.title?.toString())
        healthAction.onClickDelegate!!.sendClick(object : OnDoneCallback {})
        assertTrue(screenManager.top is CarHealthScreen)
        assertEquals(2, screenManager.stackSize)
        assertEquals(Action.BACK, (screenManager.top.onGetTemplate() as PaneTemplate).header!!.startHeaderAction)
    }

    @Test
    fun everyMetricTileOpensNumericPaneWithBackAndPowertrainAndHealthRemainsOnTheGrid() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        carContext.lifecycleOwner.registry.currentState = Lifecycle.State.RESUMED
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(screen)
        val items = (screen.onGetTemplate() as GridTemplate).items()

        items.forEach { item ->
            item.onClickDelegate!!.sendClick(object : OnDoneCallback {})
            assertNumericPaneAndReachablePowertrain(screenManager)
            screenManager.pop() // Powertrain -> numerical values.
            screenManager.pop() // Numerical values -> graphical dashboard.
            assertEquals(screen, screenManager.top)
            assertEquals(1, screenManager.stackSize)
        }

        val healthAction = (screen.onGetTemplate() as GridTemplate).header!!.endHeaderActions.single()
        healthAction.onClickDelegate!!.sendClick(object : OnDoneCallback {})
        assertTrue(screenManager.top is CarHealthScreen)
        assertEquals(2, screenManager.stackSize)
    }

    private fun assertNumericPaneAndReachablePowertrain(screenManager: ScreenManager) {
        assertTrue(screenManager.top is CarHomeScreen)
        assertEquals(2, screenManager.stackSize)
        val template = screenManager.top.onGetTemplate() as PaneTemplate
        assertEquals(Action.BACK, template.header!!.startHeaderAction)
        assertEquals(6, template.pane.rows.size)
        assertEquals("42 km/h", template.pane.rows[0].texts[0].toString())
        val powertrain = template.header!!.endHeaderActions.single()
        assertEquals("Powertrain", powertrain.title?.toString())
        powertrain.onClickDelegate!!.sendClick(object : OnDoneCallback {})
        assertTrue(screenManager.top is CarPowertrainScreen)
        assertEquals(3, screenManager.stackSize)
    }

    @Test
    fun gridToHealthToFaultSummaryToDetailUsesFourScreensWithTheSessionDtcRepository() = runTest {
        val dtcRepo = DefaultCarDtcRepository()
        val repo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
            dtcRepository = dtcRepo,
        )
        repo.submit(frameInput(speed = live(0.0)))
        dtcRepo.submit(
            CarDtcReport(
                schemaVersion = 1,
                reportSequence = 1,
                connectionEpoch = 1,
                phase = CarDtcScanPhase.IDLE,
                verdict = CarDtcVerdict.FAULTS_FOUND,
                coverageComplete = true,
                milOn = true,
                totalCodes = 1,
                freezeFrameReadIncomplete = false,
                items = listOf(
                    CarDtcItem(
                        code = "P0300",
                        kind = CarDtcKind.STORED,
                        sourceId = "7E8",
                        isManufacturerSpecific = false,
                        completeness = CarDtcCompleteness.COMPLETE,
                    ),
                ),
                freezeFrames = emptyList(),
            ),
        )
        // The runtime only wires repositories; this fixture never starts a hardware listener.
        val runtime = CarSessionRuntime(
            carContext = carContext,
            telemetryRepository = repo,
            dtcRepository = dtcRepo,
            hostSpeedGateway = object : CarHardwareSpeedGateway {
                override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) = Unit
                override fun stopListening() = Unit
            },
            coroutineScope = backgroundScope,
        )
        val screen = graphicalScreen(repo, runtime = runtime)
        carContext.lifecycleOwner.registry.currentState = Lifecycle.State.RESUMED
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(screen)
        assertEquals(1, screenManager.stackSize)

        (screen.onGetTemplate() as GridTemplate).header!!.endHeaderActions.single()
            .onClickDelegate!!.sendClick(object : OnDoneCallback {})
        assertTrue(screenManager.top is CarHealthScreen)
        assertEquals(2, screenManager.stackSize)
        val healthTemplate = screenManager.top.onGetTemplate() as PaneTemplate
        val faultCodes = healthTemplate.pane.actions.single { it.title?.toString() == "Fault Codes" }
        assertTrue(faultCodes.onClickDelegate!!.isParkedOnly)
        faultCodes.onClickDelegate!!.sendClick(object : OnDoneCallback {})

        assertTrue(screenManager.top is CarDtcSummaryScreen)
        assertEquals(3, screenManager.stackSize)
        val summary = screenManager.top.onGetTemplate() as ListTemplate
        val code = summary.singleList!!.items.filterIsInstance<Row>().single()
        assertEquals("P0300 · Stored", code.title?.toString())
        assertTrue(code.onClickDelegate!!.isParkedOnly)
        code.onClickDelegate!!.sendClick(object : OnDoneCallback {})

        assertTrue(screenManager.top is CarDtcDetailScreen)
        assertEquals(4, screenManager.stackSize)
        assertFalse(runtime.isStarted)
        screenManager.popToRoot()
        runtime.destroy()
    }

    @Test
    fun wholeRepositoryTimeoutKeepsSameEpochUnknownWarningWithoutAReading() = runTest {
        val repo = createRepository()
        val coordinator = CarAlertCoordinator(
            telemetryRepository = repo,
            clock = { testScheduler.currentTime },
            coroutineScope = backgroundScope,
        )
        repo.submit(frameInput(coolant = live(108.0)))
        coordinator.start()
        runCurrent()
        advanceTimeBy(2_000)
        repo.submit(frameInput(sequence = 2, coolant = live(108.0)))
        runCurrent()
        advanceTimeBy(1_001)
        repo.submit(frameInput(sequence = 3, coolant = live(108.0)))
        runCurrent()
        assertEquals(CarAlertPhase.ACTIVE, coordinator.repository.snapshot.value.coolant)
        val screen = graphicalScreen(repo, alerts = coordinator.repository)
        assertEquals("108 °C · High", (screen.onGetTemplate() as GridTemplate).items()[2].text?.toString())

        advanceTimeBy(CarTelemetryRepository.DEFAULT_STALE_AFTER_MS + 1)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Stale)
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, coordinator.repository.snapshot.value.coolant)
        val row = screen.buildDisplayModel(repo.state.value).rows[2]
        assertTrue(row.warning)
        assertNull(row.graphicValue)
        assertEquals("Stale", row.text)
        assertEquals("Stale", (screen.onGetTemplate() as GridTemplate).items()[2].text?.toString())
        coordinator.destroy()
    }

    @Test
    fun warningFromAnOlderEpochDoesNotAppearInCurrentOrTimedOutGridData() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(epoch = 2, coolant = live(90.0)))
        val alerts = CarAlertRepository().apply {
            updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.ATTENTION, coolant = CarAlertPhase.ACTIVE, connectionEpoch = 1))
        }
        val screen = graphicalScreen(repo, alerts = alerts)
        val current = screen.buildDisplayModel(repo.state.value).rows[2]
        assertFalse(current.warning)
        assertEquals("90 °C", current.text)
        runCurrent()
        advanceTimeBy(CarTelemetryRepository.DEFAULT_STALE_AFTER_MS + 1)
        runCurrent()

        assertTrue(repo.state.value is CarTelemetryState.Stale)
        val timedOut = screen.buildDisplayModel(repo.state.value).rows[2]
        assertFalse(timedOut.warning)
        assertNull(timedOut.graphicValue)
        assertEquals("Stale", timedOut.text)
    }

    @Test
    fun rapidTelemetryCoalescesAtOneHzAndDoesNotRefreshWithoutAnotherChange() = runTest {
        val repo = createRepository()
        var invalidations = 0
        val screen = graphicalScreen(repo).apply { onInvalidateListener = { invalidations++ } }
        ScreenController(screen).moveToState(Lifecycle.State.RESUMED)
        screen.onGetTemplate()
        runCurrent()

        repeat(10) { index ->
            advanceTimeBy(100)
            repo.submit(frameInput(sequence = index + 1L, speed = live((index + 1) * 10.0)))
            runCurrent()
            assertEquals("A burst must schedule only one pending refresh", 1, invalidations)
        }
        advanceTimeBy(100)
        runCurrent()
        assertEquals(2, invalidations)
        assertEquals("100 km/h", (screen.onGetTemplate() as GridTemplate).items()[0].text?.toString())
        advanceTimeBy(1_500)
        runCurrent()
        assertEquals("A rendered model must not create a refresh loop", 2, invalidations)
    }

    @Test
    fun rawChangesWithinTheSameDisplayedPrecisionDoNotInvalidateTheGraphic() = runTest {
        val repo = createRepository()
        var invalidations = 0
        val screen = graphicalScreen(repo).apply { onInvalidateListener = { invalidations++ } }
        ScreenController(screen).moveToState(Lifecycle.State.RESUMED)
        runCurrent()
        repo.submit(frameInput(speed = live(42.1), rpm = live(1800.1), coolant = live(89.6), voltage = live(14.11)))
        runCurrent()
        assertEquals(1, invalidations)
        val firstModel = screen.buildDisplayModel(repo.state.value)

        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 2, speed = live(42.4), rpm = live(1800.4), coolant = live(89.9), voltage = live(14.14)))
        runCurrent()
        assertEquals(firstModel, screen.buildDisplayModel(repo.state.value))
        advanceTimeBy(1_100)
        runCurrent()
        assertEquals("Bitmap values must use the same precision as native text", 1, invalidations)
    }

    @Test
    fun stopCancelsPendingGraphicRefreshAndObservation() = runTest {
        assertPendingRefreshCancelled(Lifecycle.State.CREATED)
    }

    @Test
    fun destroyCancelsPendingGraphicRefreshAndObservation() = runTest {
        assertPendingRefreshCancelled(Lifecycle.State.DESTROYED)
    }

    private fun TestScope.assertPendingRefreshCancelled(targetState: Lifecycle.State) {
        val repo = createRepository()
        var invalidations = 0
        val screen = graphicalScreen(repo).apply { onInvalidateListener = { invalidations++ } }
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)
        runCurrent()
        advanceTimeBy(100)
        repo.submit(frameInput(speed = live(10.0)))
        runCurrent()
        assertEquals(1, invalidations)
        advanceTimeBy(100)
        repo.submit(frameInput(sequence = 2, speed = live(20.0)))
        runCurrent()
        assertEquals(1, invalidations)

        controller.moveToState(targetState)
        advanceTimeBy(1_000)
        repo.submit(frameInput(sequence = 3, speed = live(30.0)))
        runCurrent()
        advanceTimeBy(1_000)
        runCurrent()
        assertEquals("Neither a pending job nor new data may invalidate an inactive screen", 1, invalidations)
    }
}

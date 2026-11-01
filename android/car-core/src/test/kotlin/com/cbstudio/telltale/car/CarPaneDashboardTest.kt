package com.cbstudio.telltale.car

import android.graphics.drawable.Icon
import androidx.car.app.HandshakeInfo
import androidx.car.app.OnDoneCallback
import androidx.car.app.ScreenManager
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
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
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Graphical Home (AA-11): PaneTemplate rows plus one large gauge image. Template and refresh
 * contracts only; actual host layout still requires DHU/device acceptance.
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CarPaneDashboardTest {

    private lateinit var carContext: TestCarContext
    private val expectedTitles = listOf("Speed", "RPM", "Coolant", "Module Voltage", "MAP", "Engine Load")

    @Before
    fun setUp() {
        Dispatchers.setMain(StandardTestDispatcher())
        carContext = TestCarContext.createCarContext(ApplicationProvider.getApplicationContext())
        carContext.updateHandshakeInfo(HandshakeInfo("test.host", 8))
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
        paneLimit: () -> Int = { 6 },
        alerts: CarAlertRepository = CarAlertRepository(),
        hostSpeed: CarHostSpeedRepository = CarHostSpeedRepository(),
        runtime: CarSessionRuntime? = null,
    ) = CarHomeScreen(
        carContext = carContext,
        repository = repository,
        contentLimitProvider = paneLimit,
        graphicalDashboard = true,
        alertRepository = alerts,
        hostSpeedRepository = hostSpeed,
        sessionRuntime = runtime,
        clock = { testScheduler.currentTime },
        coroutineScope = backgroundScope,
    )

    private fun CarHomeScreen.pane(): PaneTemplate = onGetTemplate() as PaneTemplate
    private fun PaneTemplate.titles() = pane.rows.map { it.title?.toString() }
    private fun PaneTemplate.texts() = pane.rows.map { it.texts.single().toString() }

    @Test
    fun homeIsAPaneWithFixedTitlesNativeReadingsAndOneBitmapImage() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)

        val template = screen.pane()
        assertEquals(expectedTitles, template.titles())
        assertEquals(listOf("42 km/h", "1800 RPM", "90 °C", "14.1 V", "35 kPa", "68 %"), template.texts())
        val rows = screen.buildDisplayModel(repo.state.value).rows
        assertEquals(listOf(42.0, 1800.0, 90.0, 14.1), rows.take(4).map { it.graphicValue })
        // The image numeral is the native reading without its unit, from the same formatting.
        assertEquals(listOf("42", "1800", "90", "14.1"), rows.take(4).map { it.graphicText })
        rows.take(4).zip(template.texts()).forEach { (row, text) ->
            assertTrue(text.startsWith(row.graphicText!!))
            assertEquals(CarGaugeState.LIVE, row.gaugeState)
        }
        assertFalse(template.pane.isLoading)
        assertEquals(Action.APP_ICON, template.header!!.startHeaderAction)
        assertEquals("Health", template.header!!.endHeaderActions.single().title?.toString())
        val image = requireNotNull(template.pane.image).icon!!
        assertEquals(Icon.TYPE_BITMAP, image.type)
        assertEquals(320, requireNotNull(image.bitmap).width)
    }

    @Test
    fun refreshesKeepRowCountTitlesAndHeaderAcrossEveryDataState() = runTest {
        val repo = createRepository()
        val screen = graphicalScreen(repo)
        val reference = screen.pane()
        fun assertSameShape() {
            val t = screen.pane()
            // PaneTemplate refresh rule: same title, row count and row titles.
            assertEquals(reference.header!!.title.toString(), t.header!!.title.toString())
            assertEquals(reference.titles(), t.titles())
            assertEquals(expectedTitles, t.titles())
        }
        val stale = CarSignalInput(CarSignalStatus.STALE, 1.0)
        val unsupported = CarSignalInput(CarSignalStatus.UNSUPPORTED, 0.0)
        listOf(
            frameInput(sequence = 1),
            frameInput(sequence = 2, speed = unavailable(), rpm = unavailable()),
            frameInput(sequence = 3, speed = stale, rpm = stale, coolant = stale, voltage = stale),
            frameInput(sequence = 4, speed = unsupported, rpm = unsupported, coolant = unsupported, voltage = unsupported),
            frameInput(sequence = 5, phase = CarConnectionPhase.DISCONNECTED, speed = stale, rpm = stale),
        ).forEach {
            repo.submit(it)
            assertSameShape()
        }
        runCurrent()
        advanceTimeBy(CarTelemetryRepository.DEFAULT_STALE_AFTER_MS + 1)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Stale)
        assertSameShape()
    }

    @Test
    fun missingUnsupportedCorruptAndStaleSignalsKeepRowsWithoutGraphicReadings() = runTest {
        val repo = createRepository()
        val screen = graphicalScreen(repo)

        fun assertUnavailable(text: String) {
            val template = screen.pane()
            assertEquals(expectedTitles, template.titles())
            assertEquals(List(4) { text }, template.texts().take(4))
            assertNotNull(template.pane.image)
            screen.buildDisplayModel(repo.state.value).rows.take(4).forEach {
                assertNull(it.graphicValue)
                assertNull(it.graphicText)
                assertTrue(it.gaugeState != CarGaugeState.LIVE)
            }
        }
        fun states() = screen.buildDisplayModel(repo.state.value).rows.take(4).map { it.gaugeState }

        assertUnavailable("--") // No frame was received.
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
            assertUnavailable("--")
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
        assertUnavailable("Stale")
        assertEquals(List(4) { CarGaugeState.STALE }, states())
    }

    @Test
    fun expiredFrameRemovesGraphicReadingsInsteadOfRetainingTheLastOne() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        assertTrue(screen.buildDisplayModel(repo.state.value).rows.take(4).all { it.graphicValue != null })
        runCurrent()
        advanceTimeBy(CarTelemetryRepository.DEFAULT_STALE_AFTER_MS + 1)
        runCurrent()

        assertTrue(repo.state.value is CarTelemetryState.Stale)
        assertEquals(List(4) { "Stale" }, screen.pane().texts().take(4))
        screen.buildDisplayModel(repo.state.value).rows.take(4).forEach {
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
        val stale = CarSignalInput(CarSignalStatus.STALE, 42.0)
        repo.submit(frameInput(sequence = 2, phase = CarConnectionPhase.DISCONNECTED, speed = stale, rpm = stale, coolant = stale, voltage = stale))
        assertEquals(List(4) { "Stale" }, screen.pane().texts().take(4))
        screen.buildDisplayModel(repo.state.value).rows.take(4).forEach { assertNull(it.graphicValue) }

        repo.submit(frameInput(sequence = 3, phase = CarConnectionPhase.DISCONNECTED, speed = unavailable(), rpm = unavailable(), coolant = unavailable(), voltage = unavailable()))
        assertEquals(List(4) { "--" }, screen.pane().texts().take(4))
        screen.buildDisplayModel(repo.state.value).rows.take(4).forEach { assertNull(it.graphicValue) }
    }

    @Test
    fun speedGraphicUsesTheSameHostFallbackAsTheNativeValue() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(speed = unavailable()))
        val hostSpeed = CarHostSpeedRepository().apply {
            updateSample(CarHostSpeedSample(status = CarHostSpeedStatus.LIVE, displaySpeedMetersPerSecond = 15f))
        }
        val screen = graphicalScreen(repo, hostSpeed = hostSpeed)

        assertEquals("54 km/h", screen.pane().texts()[0])
        assertEquals("54", screen.buildDisplayModel(repo.state.value).rows[0].graphicText)
    }

    @Test
    fun paneRowLimitIsResolvedOnceAndRespectsSmallHostLimits() = runTest {
        val repo = createRepository()
        var calls = 0
        var hostLimit = 2
        val screen = graphicalScreen(repo, paneLimit = { calls++; hostLimit })
        hostLimit = 6
        repeat(3) { index ->
            repo.submit(frameInput(sequence = index + 1L, speed = live(index * 10.0)))
            assertEquals(expectedTitles.take(2), screen.pane().titles())
        }
        assertEquals(1, calls)
        listOf(1, 4, 10).forEach { limit ->
            assertEquals(minOf(limit, 6), graphicalScreen(repo, paneLimit = { limit }).pane().pane.rows.size)
        }
    }

    @Test
    fun imageNeedsCarApi4AndUnknownOrOlderHostsGetTheSameRowsWithoutIt() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        assertNotNull(graphicalScreen(repo).pane().pane.image)

        carContext = TestCarContext.createCarContext(ApplicationProvider.getApplicationContext())
        val unknown = graphicalScreen(repo).pane() // No handshake yet.
        assertNull(unknown.pane.image)
        assertEquals(expectedTitles, unknown.titles())

        carContext.updateHandshakeInfo(HandshakeInfo("test.host", 3))
        val older = graphicalScreen(repo).pane()
        assertNull(older.pane.image)
        assertEquals(expectedTitles, older.titles())
        carContext.updateHandshakeInfo(HandshakeInfo("test.host", 4))
        assertNotNull(graphicalScreen(repo).pane().pane.image)
    }

    @Test
    fun imageFailureLeavesTheRowsAndActionsIntact() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        listOf<(List<CarHomeScreen.MetricRow>, Boolean) -> CarIcon?>(
            { _, _ -> throw IllegalStateException("Bitmap unavailable") },
            { _, _ -> throw OutOfMemoryError("Image preparation unavailable") },
            { _, _ -> null },
        ).forEach { failing ->
            val screen = graphicalScreen(repo).apply { dashboardImage = failing }
            val template = screen.pane()
            assertNull(template.pane.image)
            assertEquals(expectedTitles, template.titles())
            assertEquals("42 km/h", template.texts()[0])
            assertEquals("Health", template.header!!.endHeaderActions.single().title?.toString())
        }
    }

    @Test
    fun numericalHomeKeepsRowsOnlyAndNoGaugeFields() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = CarHomeScreen(carContext = carContext, repository = repo, contentLimitProvider = { 6 })
        val template = screen.pane()
        assertNull(template.pane.image)
        screen.buildDisplayModel(repo.state.value).rows.forEach {
            assertNull(it.graphicValue)
            assertNull(it.graphicText)
            assertEquals(CarGaugeState.NO_DATA, it.gaugeState)
        }
    }

    @Test
    fun dayAndNightImagesDifferAndFollowCarContext() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        val day = screen.pane().pane.image!!.icon!!.bitmap!!
        val night = graphicalScreen(repo).let { s ->
            s.dashboardImage(s.buildDisplayModel(repo.state.value).rows, true)!!.icon!!.bitmap!!
        }
        assertFalse(carContext.isDarkMode)
        assertFalse(day.sameAs(night))
    }

    @Test
    fun pendingClearCoolantKeepsWarningTextAndRedIconUntilNormal() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(coolant = live(99.0)))
        val alerts = CarAlertRepository()
        val screen = graphicalScreen(repo, alerts = alerts)

        alerts.updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.ATTENTION, coolant = CarAlertPhase.PENDING_CLEAR, connectionEpoch = 1))
        val pending = screen.buildDisplayModel(repo.state.value).rows[2]
        val pendingRow = screen.pane().pane.rows[2]
        assertTrue(pending.warning)
        assertEquals("99", pending.graphicText)
        assertEquals("99 °C · High", pendingRow.texts.single().toString())
        assertEquals(CarColor.RED, pendingRow.image!!.tint)

        alerts.updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.NORMAL, coolant = CarAlertPhase.NORMAL, connectionEpoch = 1))
        assertFalse(screen.buildDisplayModel(repo.state.value).rows[2].warning)
        val normalRow = screen.pane().pane.rows[2]
        assertEquals("99 °C", normalRow.texts.single().toString())
        assertFalse(CarColor.RED == normalRow.image!!.tint)
    }

    @Test
    fun activeAndUnknownCoolantWarningsKeepTextIconAndGraphicStateConsistent() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(coolant = live(108.0)))
        val alerts = CarAlertRepository()
        val screen = graphicalScreen(repo, alerts = alerts)

        alerts.updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.ATTENTION, coolant = CarAlertPhase.ACTIVE, connectionEpoch = 1))
        val active = screen.buildDisplayModel(repo.state.value).rows[2]
        val activeRow = screen.pane().pane.rows[2]
        assertTrue(active.warning)
        assertEquals("108", active.graphicText)
        assertEquals("108 °C · High", activeRow.texts.single().toString())
        assertEquals(CarColor.RED, activeRow.image!!.tint)

        repo.submit(frameInput(sequence = 2, coolant = CarSignalInput(CarSignalStatus.STALE, null)))
        alerts.updateSnapshot(CarAlertSnapshot(level = CarAlertLevel.UNKNOWN, coolant = CarAlertPhase.UNKNOWN_AFTER_WARNING, connectionEpoch = 1))
        val unknown = screen.buildDisplayModel(repo.state.value).rows[2]
        assertTrue(unknown.warning)
        assertNull(unknown.graphicValue)
        assertNull(unknown.graphicText)
        assertEquals(CarGaugeState.STALE, unknown.gaugeState)
        assertEquals("Stale", screen.pane().texts()[2])
    }

    @Test
    fun headerOpensHealthAndHealthStillReachesPowertrain() = runTest {
        val repo = createRepository()
        repo.submit(frameInput())
        val screen = graphicalScreen(repo)
        carContext.lifecycleOwner.registry.currentState = Lifecycle.State.RESUMED
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(screen)

        val healthAction = screen.pane().header!!.endHeaderActions.single()
        assertEquals("Health", healthAction.title?.toString())
        healthAction.onClickDelegate!!.sendClick(object : OnDoneCallback {})
        assertTrue(screenManager.top is CarHealthScreen)
        assertEquals(2, screenManager.stackSize)
        val health = screenManager.top.onGetTemplate() as PaneTemplate
        assertEquals(Action.BACK, health.header!!.startHeaderAction)
        health.pane.actions.single { it.title?.toString() == "Powertrain" }
            .onClickDelegate!!.sendClick(object : OnDoneCallback {})
        assertTrue(screenManager.top is CarPowertrainScreen)
        assertEquals(3, screenManager.stackSize)
        screenManager.pop()
        screenManager.pop()
        assertEquals(screen, screenManager.top)
    }

    @Test
    fun homeToHealthToFaultSummaryToDetailUsesFourScreensWithTheSessionDtcRepository() = runTest {
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

        screen.pane().header!!.endHeaderActions.single()
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
        assertEquals("108 °C · High", screen.pane().texts()[2])

        advanceTimeBy(CarTelemetryRepository.DEFAULT_STALE_AFTER_MS + 1)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Stale)
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, coordinator.repository.snapshot.value.coolant)
        val row = screen.buildDisplayModel(repo.state.value).rows[2]
        assertTrue(row.warning)
        assertNull(row.graphicValue)
        assertEquals("Stale", row.text)
        assertEquals("Stale", screen.pane().texts()[2])
        coordinator.destroy()
    }

    @Test
    fun warningFromAnOlderEpochDoesNotAppearInCurrentOrTimedOutData() = runTest {
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
        assertEquals("100 km/h", screen.pane().texts()[0])
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
        assertEquals("Image readings must use the same precision as native text", 1, invalidations)
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

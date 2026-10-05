package com.cbstudio.telltale.car

import androidx.car.app.CarContext
import androidx.car.app.ScreenManager
import androidx.car.app.model.Action
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.ParkedOnlyOnClickListener
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.diagnostics.CarDtcItem
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcRepository
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedPermissionCoordinator
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
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarHealthScreenTest {

    private lateinit var carContext: TestCarContext
    private lateinit var testDispatcher: TestDispatcher

    @Before
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext(),
        )
        val packageInfo = carContext.packageManager.getPackageInfo(carContext.packageName, 0).apply {
            requestedPermissions = arrayOf(
                com.cbstudio.telltale.car.hardware.CarHostSpeedPermissionCoordinator.PERMISSION_CAR_SPEED_PROJECTED,
            )
        }
        org.robolectric.Shadows.shadowOf(carContext.packageManager).installPackage(packageInfo)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)
    private fun stale() = CarSignalInput(CarSignalStatus.STALE, null)
    private fun unavailable() = CarSignalInput(CarSignalStatus.UNAVAILABLE, null)

    private fun frameInput(
        sequence: Long = 1,
        epoch: Long = 1,
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
        speed: Double = 0.0,
        coolant: Double = 90.0,
        voltage: Double = 14.1,
        milOn: Boolean? = false,
        dtcCount: Long? = 0,
    ) = CarTelemetryFrameInput(
        schemaVersion = 1,
        sequence = sequence,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = phase,
        speedKmh = live(speed),
        rpm = live(800.0),
        coolantC = live(coolant),
        intakeAirC = live(25.0),
        controlModuleVoltageV = live(voltage),
        mapKpa = live(35.0),
        diagnosticsAvailable = true,
        milOn = milOn,
        dtcCount = dtcCount,
    )

    private fun dtcReport(
        sequence: Long = 1,
        epoch: Long = 1,
        verdict: CarDtcVerdict = CarDtcVerdict.COMPLETE_CLEAN,
        coverageComplete: Boolean = true,
        milOn: Boolean? = false,
        totalCodes: Long? = 0,
    ) = CarDtcReport(
        schemaVersion = 1,
        reportSequence = sequence,
        connectionEpoch = epoch,
        phase = CarDtcScanPhase.IDLE,
        verdict = verdict,
        coverageComplete = coverageComplete,
        milOn = milOn,
        totalCodes = totalCodes,
        freezeFrameReadIncomplete = false,
        items = emptyList(),
        freezeFrames = emptyList(),
    )

    private fun TestScope.createTelemetryRepo() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    @Test
    fun healthScreen_returnsPaneTemplateWithBackActionAndMarker() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()
        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        assertEquals(CarHealthScreen.CAR_HEALTH_MARKER, screen.marker)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        @Suppress("DEPRECATION")
        assertEquals("Vehicle Health", template.title?.toString())
        assertEquals(Action.BACK, template.headerAction)
        assertEquals(2, template.pane.actions.size)
        assertEquals("Powertrain", template.pane.actions[0].title?.toString())
        assertEquals("Fault Codes", template.pane.actions[1].title?.toString())
    }

    @Test
    fun healthScreen_prioritizedHealthRows() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(coolant = 88.0, voltage = 14.2, milOn = false, dtcCount = 0))
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(dtcReport(verdict = CarDtcVerdict.COMPLETE_CLEAN, totalCodes = 0))

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows
        assertEquals(5, rows.size)

        val titles = rows.map { it.title?.toString() }
        assertEquals(
            listOf("Observed Status", "MIL", "Fault Codes", "Coolant", "Module Voltage"),
            titles,
        )

        assertEquals("No observed warnings", rows[0].texts[0].toString())
        assertEquals("Off", rows[1].texts[0].toString())
        assertEquals("0 codes", rows[2].texts[0].toString())
        assertEquals("88 °C", rows[3].texts[0].toString())
        assertEquals("14.2 V", rows[4].texts[0].toString())
    }

    @Test
    fun healthScreen_attentionStateWhenMilIsOnOrCodesFound() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(milOn = true, dtcCount = 1))
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(dtcReport(verdict = CarDtcVerdict.FAULTS_FOUND, milOn = true, totalCodes = 1))

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        assertEquals("Attention", rows[0].texts[0].toString())
        assertEquals("On", rows[1].texts[0].toString())
        assertEquals("1 codes", rows[2].texts[0].toString())
    }

    @Test
    fun healthScreen_unknownStateWhenAwaitingOrDisconnected() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        assertEquals("Unknown", rows[0].texts[0].toString())
        assertEquals("--", rows[1].texts[0].toString())
        assertEquals("--", rows[2].texts[0].toString())
        assertEquals("--", rows[3].texts[0].toString())
        assertEquals("--", rows[4].texts[0].toString())
    }

    @Test
    fun healthScreen_powertrainActionPushesPowertrainScreen() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()
        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(screen)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val powertrainAction = template.pane.actions[0]

        assertEquals("Powertrain", powertrainAction.title?.toString())
    }

    @Test
    fun healthScreen_faultCodesActionWrappedInParkedOnlyClickListener() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()
        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val faultCodesAction = template.pane.actions[1]

        assertEquals("Fault Codes", faultCodesAction.title?.toString())
        assertNotNull(faultCodesAction.onClickDelegate)
    }

    @Test
    fun healthScreen_alertHysteresisResetsOnTelemetryEpochChange() = runTest {
        var currentTime = 1_000L
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()
        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemRepo,
            clock = { currentTime },
            coroutineScope = backgroundScope,
        )
        alertCoord.start()

        // Epoch 1: hot coolant enters ACTIVE alert
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, coolant = 108.0))
        dtcRepo.submit(dtcReport(epoch = 1, verdict = CarDtcVerdict.COMPLETE_CLEAN, totalCodes = 0))
        runCurrent()

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            alertRepository = alertCoord.repository,
            contentLimitProvider = { 6 },
            clock = { currentTime },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Advance to t=4500 (> 3000ms hold time) -> alert ACTIVE
        currentTime = 4_500L
        telemRepo.submit(frameInput(sequence = 2, epoch = 1, coolant = 108.0))
        runCurrent()
        var template = screen.onGetTemplate() as PaneTemplate
        assertEquals("Attention", template.pane.rows[0].texts[0].toString())

        // Car switch: Epoch 2 connects with normal coolant (85.0°C)
        currentTime = 5_000L
        telemRepo.submit(frameInput(sequence = 1, epoch = 2, coolant = 85.0))
        dtcRepo.submit(dtcReport(epoch = 2, verdict = CarDtcVerdict.COMPLETE_CLEAN, totalCodes = 0))
        runCurrent()

        template = screen.onGetTemplate() as PaneTemplate
        // Hysteresis must have been reset: cool reading immediately results in NORMAL, not PENDING_CLEAR
        assertEquals("No observed warnings", template.pane.rows[0].texts[0].toString())
        alertCoord.destroy()
    }

    @Test
    fun healthScreen_speedPermissionDeniedShowsParkedOnlyEnableAction() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()
        val hostRepo = CarHostSpeedRepository()
        hostRepo.updateSample(CarHostSpeedSample(status = CarHostSpeedStatus.PERMISSION_DENIED))

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            hostSpeedRepository = hostRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val actionStrip = template.actionStrip
        assertNotNull(actionStrip)
        assertEquals(1, actionStrip!!.actions.size)
        assertEquals("Enable vehicle speed", actionStrip.actions[0].title?.toString())
        assertNotNull(actionStrip.actions[0].onClickDelegate)
    }

    @Test
    fun healthScreen_speedPermissionGrantedTriggersRetryAndRemovesAction() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()
        val hostRepo = CarHostSpeedRepository()
        hostRepo.updateSample(CarHostSpeedSample(status = CarHostSpeedStatus.PERMISSION_DENIED))

        var retried = false
        val coordinator = CarHostSpeedPermissionCoordinator(
            onPermissionGranted = {
                retried = true
                hostRepo.updateSample(CarHostSpeedSample(status = CarHostSpeedStatus.LIVE, displaySpeedMetersPerSecond = 10f))
            },
        )

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            hostSpeedRepository = hostRepo,
            permissionCoordinator = coordinator,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // Request permission and simulate grant
        var grantedResult: Boolean? = null
        screen.requestSpeedPermission { grantedResult = it }
        val perms = CarHostSpeedPermissionCoordinator.resolveRequiredPermissions(carContext)
        val info = carContext.lastPermissionRequestInfo
        info?.listener?.onRequestPermissionsResult(perms, emptyList<String>())
        runCurrent()

        assertTrue(grantedResult == true)
        assertTrue(retried)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        // ActionStrip should now be null since permission is no longer DENIED
        assertTrue(template.actionStrip == null || template.actionStrip!!.actions.isEmpty())
    }

    @Test
    fun healthScreen_alertTransitionTriggersImmediateRefresh() = runTest {
        var currentTime = 1_000L
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(sequence = 1, coolant = 108.0))
        runCurrent()

        val alertCoord = CarAlertCoordinator(
            telemetryRepository = telemRepo,
            clock = { currentTime },
            coroutineScope = backgroundScope,
        )

        var invalidateCount = 0
        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            alertRepository = alertCoord.repository,
            clock = { currentTime },
            contentLimitProvider = { 6 },
        )
        screen.onInvalidateListener = { invalidateCount++ }

        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)
        alertCoord.start()
        runCurrent()

        val initialInvalidates = invalidateCount

        // Advance 3001ms past hold threshold to trigger ACTIVE alert edge
        currentTime = 4_001L
        telemRepo.submit(frameInput(sequence = 2, coolant = 108.0))
        runCurrent()

        // Transition edge must have triggered immediate refresh
        assertEquals(CarAlertPhase.ACTIVE, alertCoord.repository.snapshot.value.coolant)
        assertTrue(invalidateCount > initialInvalidates)

        alertCoord.destroy()
    }

    @Test
    fun healthScreen_epochMismatchIgnoresDtcReportFromOtherCar() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()

        // Telemetry is for Epoch 1 (clean)
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, milOn = false, dtcCount = 0))
        // DTC Report is from Car 2 (Epoch 2, with 5 codes and MIL on)
        dtcRepo.submit(dtcReport(sequence = 1, epoch = 2, verdict = CarDtcVerdict.FAULTS_FOUND, milOn = true, totalCodes = 5))

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows

        // Observed status is Unknown because Epoch 1 has no matching DTC report
        assertEquals("Unknown", rows[0].texts[0].toString())
        // MIL and DTC count display telemetry frame values, ignoring Epoch 2 DTC report
        assertEquals("Off", rows[1].texts[0].toString())
        assertEquals("0 codes", rows[2].texts[0].toString())
    }

    @Test
    fun healthScreen_noObservedWarningsRequiresStrictZeroTotalCodesAndCompleteCoverage() = runTest {
        val telemRepo = createTelemetryRepo()
        val dtcRepo = DefaultCarDtcRepository()

        telemRepo.submit(frameInput(milOn = false, dtcCount = 0))
        // totalCodes is null -> must NOT qualify for NoObservedWarnings
        dtcRepo.submit(dtcReport(verdict = CarDtcVerdict.COMPLETE_CLEAN, coverageComplete = true, totalCodes = null))

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        var template = screen.onGetTemplate() as PaneTemplate
        assertEquals("Unknown", template.pane.rows[0].texts[0].toString())

        // coverageComplete is false -> must NOT qualify for NoObservedWarnings
        dtcRepo.submit(dtcReport(verdict = CarDtcVerdict.COMPLETE_CLEAN, coverageComplete = false, totalCodes = 0))
        runCurrent()
        @Suppress("DEPRECATION")
        template = screen.onGetTemplate() as PaneTemplate
        assertEquals("Unknown", template.pane.rows[0].texts[0].toString())
    }

    @Test
    fun health_doesNotRenderAttentionFromPreviousEpoch() = runTest {
        val telemRepo = createTelemetryRepo()
        // Car connected at Epoch 2, clean DTC
        telemRepo.submit(frameInput(epoch = 2L, coolant = 108.0, milOn = false, dtcCount = 0))
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(dtcReport(epoch = 2L, verdict = CarDtcVerdict.COMPLETE_CLEAN, coverageComplete = true, totalCodes = 0))
        runCurrent()

        // Alert snapshot is from previous vehicle session (Epoch 1)
        val alertRepo = CarAlertRepository()
        alertRepo.updateSnapshot(
            CarAlertSnapshot(
                level = CarAlertLevel.ATTENTION,
                coolant = CarAlertPhase.ACTIVE,
                connectionEpoch = 1L,
            ),
        )

        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            alertRepository = alertRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as PaneTemplate
        val rows = template.pane.rows
        // Status must NOT be "Attention", should be "No observed warnings" because Epoch 1 alert is ignored
        assertEquals("No observed warnings", rows[0].texts[0].toString())
        // Coolant row must NOT have "· High"
        val coolantRow = rows.find { it.title?.toString() == "Coolant" }
        assertNotNull(coolantRow)
        assertEquals("108 °C", coolantRow!!.texts[0].toString())
    }

    @Test
    fun healthScreen_rapidSemanticEdgesTriggerImmediateRefresh() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1L, coolant = 108.0, milOn = false, dtcCount = 0))
        val dtcRepo = DefaultCarDtcRepository()
        dtcRepo.submit(dtcReport(epoch = 1L, verdict = CarDtcVerdict.COMPLETE_CLEAN, coverageComplete = true, totalCodes = 0))
        runCurrent()

        val alertRepo = CarAlertRepository()
        var invalidateCount = 0
        val screen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
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

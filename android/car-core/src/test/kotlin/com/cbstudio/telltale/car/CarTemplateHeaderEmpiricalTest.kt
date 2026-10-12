package com.cbstudio.telltale.car

import androidx.car.app.model.Action
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.PaneTemplate
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
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
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
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Empirical challenge tests verifying Car App Library 1.8.0-rc01 Header.Builder migration:
 * - Direct verification of template.header fields: title, startHeaderAction, endHeaderActions.
 * - Verification of backward compatibility accessors: template.title, template.headerAction, template.actionStrip.
 * - Stress verification across all 5 production Screen classes under normal and edge conditions.
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarTemplateHeaderEmpiricalTest {

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
    ) = CarTelemetryFrameInput(
        schemaVersion = 2,
        sequence = sequence,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh = live(speed),
        rpm = live(800.0),
        coolantC = live(90.0),
        intakeAirC = live(25.0),
        controlModuleVoltageV = live(14.0),
        mapKpa = live(35.0),
        diagnosticsAvailable = true,
        milOn = false,
        dtcCount = 0,
    )

    private fun TestScope.createTelemetryRepo() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    // =========================================================================
    // 1. CarHomeScreen
    // =========================================================================

    @Test
    fun homeScreen_headerStructure_correctlyConfigured() = runTest {
        val telemRepo = createTelemetryRepo()
        val screen = CarHomeScreen(
            carContext = carContext,
            repository = telemRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as PaneTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_app_name), header!!.title?.toString())
        assertEquals(Action.APP_ICON, header.startHeaderAction)
        assertEquals(1, header.endHeaderActions.size)
        assertEquals(carContext.getString(R.string.car_action_health), header.endHeaderActions[0].title?.toString())

        // Backward compatibility getters
        @Suppress("DEPRECATION")
        assertEquals(carContext.getString(R.string.car_app_name), template.title?.toString())
        @Suppress("DEPRECATION")
        assertEquals(Action.APP_ICON, template.headerAction)
        @Suppress("DEPRECATION")
        assertNotNull(template.actionStrip)
        @Suppress("DEPRECATION")
        assertEquals(1, template.actionStrip!!.actions.size)
    }

    // =========================================================================
    // 2. CarHealthScreen
    // =========================================================================

    @Test
    fun healthScreen_headerStructure_default_withoutEndActions() = runTest {
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

        val template = screen.onGetTemplate() as PaneTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_health_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
        assertTrue("Header should have no end header actions by default", header.endHeaderActions.isEmpty())

        // Backward compatibility getters
        @Suppress("DEPRECATION")
        assertEquals(carContext.getString(R.string.car_health_title), template.title?.toString())
        @Suppress("DEPRECATION")
        assertEquals(Action.BACK, template.headerAction)
    }

    @Test
    fun healthScreen_headerStructure_permissionDenied_includesEnableSpeedEndAction() = runTest {
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

        val template = screen.onGetTemplate() as PaneTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_health_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
        assertEquals(1, header.endHeaderActions.size)
        assertEquals(carContext.getString(R.string.car_action_enable_speed), header.endHeaderActions[0].title?.toString())

        // Backward compatibility actionStrip
        @Suppress("DEPRECATION")
        val actionStrip = template.actionStrip
        assertNotNull(actionStrip)
        assertEquals(1, actionStrip!!.actions.size)
        assertEquals(carContext.getString(R.string.car_action_enable_speed), actionStrip.actions[0].title?.toString())
    }

    // =========================================================================
    // 3. CarPowertrainScreen
    // =========================================================================

    @Test
    fun powertrainScreen_headerStructure_correctlyConfigured() = runTest {
        val telemRepo = createTelemetryRepo()
        val screen = CarPowertrainScreen(
            carContext = carContext,
            repository = telemRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as PaneTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_powertrain_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
        assertTrue("Header should have no end actions", header.endHeaderActions.isEmpty())

        // Backward compatibility getters
        @Suppress("DEPRECATION")
        assertEquals(carContext.getString(R.string.car_powertrain_title), template.title?.toString())
        @Suppress("DEPRECATION")
        assertEquals(Action.BACK, template.headerAction)
    }

    // =========================================================================
    // 4. CarDtcSummaryScreen
    // =========================================================================

    @Test
    fun dtcSummaryScreen_headerStructure_stationaryNormal() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val screen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            coroutineScope = backgroundScope,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as ListTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_dtc_summary_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
        assertTrue(header.endHeaderActions.isEmpty())

        // Backward compatibility getters
        @Suppress("DEPRECATION")
        assertEquals(carContext.getString(R.string.car_dtc_summary_title), template.title?.toString())
        @Suppress("DEPRECATION")
        assertEquals(Action.BACK, template.headerAction)
    }

    @Test
    fun dtcSummaryScreen_headerStructure_movingFallback() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(speed = 40.0))
        val dtcRepo = DefaultCarDtcRepository()
        val screen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            coroutineScope = backgroundScope,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as ListTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_dtc_summary_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
    }

    // =========================================================================
    // 5. CarDtcDetailScreen
    // =========================================================================

    @Test
    fun dtcDetailScreen_headerStructure_withValidReportAndItem() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        val report = CarDtcReport(
            schemaVersion = 1,
            reportSequence = 1,
            connectionEpoch = 1,
            phase = CarDtcScanPhase.IDLE,
            verdict = CarDtcVerdict.FAULTS_FOUND,
            coverageComplete = true,
            milOn = true,
            totalCodes = 1,
            freezeFrameReadIncomplete = false,
            items = listOf(item),
            freezeFrames = emptyList(),
        )
        dtcRepo.submit(report)

        val screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as ListTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals("P0300", header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
        assertTrue(header.endHeaderActions.isEmpty())

        // Backward compatibility getters
        @Suppress("DEPRECATION")
        assertEquals("P0300", template.title?.toString())
        @Suppress("DEPRECATION")
        assertEquals(Action.BACK, template.headerAction)
    }

    @Test
    fun dtcDetailScreen_headerStructure_missingReportFallback() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )

        val screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as ListTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_dtc_detail_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
    }

    @Test
    fun dtcDetailScreen_headerStructure_movingFallback() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(speed = 25.0))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )

        val screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as ListTemplate
        val header = template.header

        assertNotNull("Template must expose Header object", header)
        assertEquals(carContext.getString(R.string.car_dtc_detail_title), header!!.title?.toString())
        assertEquals(Action.BACK, header.startHeaderAction)
    }
}

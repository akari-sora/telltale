package com.cbstudio.telltale.car

import androidx.car.app.ScreenManager
import androidx.car.app.model.Action
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
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.CarFreezeFrame
import com.cbstudio.telltale.car.diagnostics.CarFreezeReading
import com.cbstudio.telltale.car.diagnostics.CarFreezeSignalKind
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
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
class CarDtcScreensTest {

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
    ) =
        CarTelemetryFrameInput(
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

    private fun TestScope.createTelemetryRepo() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    @Test
    fun summaryScreen_emptyReportVerdictAware() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()

        val screen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        // 1. Initial awaiting state -> Diagnostics unavailable / incomplete
        var template = screen.onGetTemplate() as ListTemplate
        var items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Diagnostics unavailable / incomplete", items[0].title?.toString())

        // 2. COMPLETE_CLEAN -> No diagnostic codes observed
        dtcRepo.submit(CarDtcReport(1, 1, 1, CarDtcScanPhase.IDLE, CarDtcVerdict.COMPLETE_CLEAN, true, false, 0, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("No diagnostic codes observed", items[0].title?.toString())

        // 3. NOT_SCANNED -> Not scanned
        dtcRepo.submit(CarDtcReport(1, 2, 1, CarDtcScanPhase.IDLE, CarDtcVerdict.NOT_SCANNED, false, null, null, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Not scanned", items[0].title?.toString())

        // 4. SCANNING -> Scan in progress
        dtcRepo.submit(CarDtcReport(1, 3, 1, CarDtcScanPhase.SCANNING, CarDtcVerdict.NOT_SCANNED, false, null, null, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Scan in progress", items[0].title?.toString())

        // 5. PARTIAL_CLEAN -> Coverage incomplete / no faults observed in completed portions
        dtcRepo.submit(CarDtcReport(1, 4, 1, CarDtcScanPhase.IDLE, CarDtcVerdict.PARTIAL_CLEAN, false, false, 0, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Coverage incomplete / no faults observed in completed portions", items[0].title?.toString())

        // 6. FAILED -> Diagnostics unavailable / incomplete
        dtcRepo.submit(CarDtcReport(1, 5, 1, CarDtcScanPhase.IDLE, CarDtcVerdict.FAILED, false, null, null, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Diagnostics unavailable / incomplete", items[0].title?.toString())

        // 7. INTERRUPTED -> Diagnostics unavailable / incomplete
        dtcRepo.submit(CarDtcReport(1, 6, 1, CarDtcScanPhase.INTERRUPTED, CarDtcVerdict.PARTIAL_CLEAN, false, null, null, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Diagnostics unavailable / incomplete", items[0].title?.toString())

        // 8. Epoch mismatch -> Diagnostics unavailable / incomplete
        dtcRepo.submit(CarDtcReport(1, 7, 2, CarDtcScanPhase.IDLE, CarDtcVerdict.COMPLETE_CLEAN, true, false, 0, false, emptyList(), emptyList()))
        runCurrent()
        template = screen.onGetTemplate() as ListTemplate
        items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Diagnostics unavailable / incomplete", items[0].title?.toString())
    }

    @Test
    fun summaryScreen_displaysDtcItemsWithDetails() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()
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

        val screen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as ListTemplate
        val items = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, items.size)
        assertEquals("P0300 · Stored", items[0].title?.toString())
        assertEquals("Controller 7E8", items[0].texts[0].toString())
        assertEquals("Complete", items[0].texts[1].toString())
    }

    @Test
    fun summaryScreen_exceedingListLimitDisplaysOverflowRow() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()

        val dtcList = (1..10).map { i ->
            CarDtcItem(
                code = "P030$i",
                kind = CarDtcKind.STORED,
                sourceId = "7E8",
                isManufacturerSpecific = false,
                completeness = CarDtcCompleteness.COMPLETE,
            )
        }

        dtcRepo.submit(
            CarDtcReport(
                schemaVersion = 1,
                reportSequence = 1,
                connectionEpoch = 1,
                phase = CarDtcScanPhase.IDLE,
                verdict = CarDtcVerdict.FAULTS_FOUND,
                coverageComplete = true,
                milOn = true,
                totalCodes = 10,
                freezeFrameReadIncomplete = false,
                items = dtcList,
                freezeFrames = emptyList(),
            ),
        )

        val screen = CarDtcSummaryScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
            contentLimitProvider = { 4 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        // Limit is 4: 3 items + 1 overflow row
        assertEquals(4, rows.size)
        assertEquals("P0301 · Stored", rows[0].title?.toString())
        assertEquals("P0302 · Stored", rows[1].title?.toString())
        assertEquals("P0303 · Stored", rows[2].title?.toString())
        assertEquals("7 additional diagnostic codes not shown", rows[3].title?.toString())
    }

    @Test
    fun detailScreen_rendersDtcInfoAndFreezeFrameReadings() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0171",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )

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
                items = listOf(item),
                freezeFrames = listOf(
                    CarFreezeFrame(
                        sourceId = "7E8",
                        frameNumber = 0,
                        causeCode = "P0171",
                        causeKind = CarDtcKind.STORED,
                        causeSourceId = "7E8",
                        readings = listOf(
                            CarFreezeReading(CarFreezeSignalKind.COOLANT_C, 104.0),
                            CarFreezeReading(CarFreezeSignalKind.SPEED_KMH, 80.0),
                        ),
                        undecodableCount = 0,
                        unreadCount = 0,
                        omittedByProjectionCount = 1,
                        contentsUnknown = false,
                    ),
                ),
            ),
        )

        val screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            contentLimitProvider = { 6 },
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as ListTemplate
        @Suppress("DEPRECATION")
        assertEquals("P0171", template.title?.toString())
        assertEquals(Action.BACK, template.headerAction)

        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        // 3 metadata + 2 readings + 1 omitted summary row = 6 rows
        assertEquals(6, rows.size)
        assertEquals("Class", rows[0].title?.toString())
        assertEquals("Stored", rows[0].texts[0].toString())
        assertEquals("Controller", rows[1].title?.toString())
        assertEquals("7E8", rows[1].texts[0].toString())
        assertEquals("Coverage", rows[2].title?.toString())
        assertEquals("Complete", rows[2].texts[0].toString())
        assertEquals("Coolant", rows[3].title?.toString())
        assertEquals("104 °C", rows[3].texts[0].toString())
        assertEquals("Speed", rows[4].title?.toString())
        assertEquals("80 km/h", rows[4].texts[0].toString())
        assertEquals("Freeze Frame", rows[5].title?.toString())
        assertEquals("Incomplete data · 1 signals unread or omitted", rows[5].texts[0].toString())
    }

    @Test
    fun detailScreen_freezeFrameLookupRequiresCauseKindAndCauseSourceIdMatch() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )

        // Freeze frame has same code P0300, but causeKind is PENDING instead of STORED
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
                items = listOf(item),
                freezeFrames = listOf(
                    CarFreezeFrame(
                        sourceId = "7E8",
                        frameNumber = 0,
                        causeCode = "P0300",
                        causeKind = CarDtcKind.PENDING,
                        causeSourceId = "7E8",
                        readings = listOf(CarFreezeReading(CarFreezeSignalKind.RPM, 2000.0)),
                        undecodableCount = 0,
                        unreadCount = 0,
                        omittedByProjectionCount = 0,
                        contentsUnknown = false,
                    ),
                ),
            ),
        )

        val screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        // Freeze frame must NOT match because causeKind (PENDING) != item.kind (STORED)
        assertEquals(4, rows.size)
        assertEquals("Freeze Frame", rows[3].title?.toString())
        assertEquals("No freeze frame available", rows[3].texts[0].toString())
    }

    @Test
    fun detailScreen_anonymousDtcDoesNotConsumeAttributedFreezeFrame() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()
        // Anonymous DTC with sourceId = null
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = null,
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )

        // Freeze frame has same code and kind, but causeSourceId = "7E8"
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
                items = listOf(item),
                freezeFrames = listOf(
                    CarFreezeFrame(
                        sourceId = "7E8",
                        frameNumber = 0,
                        causeCode = "P0300",
                        causeKind = CarDtcKind.STORED,
                        causeSourceId = "7E8",
                        readings = listOf(CarFreezeReading(CarFreezeSignalKind.RPM, 2000.0)),
                        undecodableCount = 0,
                        unreadCount = 0,
                        omittedByProjectionCount = 0,
                        contentsUnknown = false,
                    ),
                ),
            ),
        )

        val screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
        )
        val controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        val template = screen.onGetTemplate() as ListTemplate
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        // Must NOT match: causeSourceId ("7E8") != item.sourceId (null)
        assertEquals(4, rows.size)
        assertEquals("Freeze Frame", rows[3].title?.toString())
        assertEquals("No freeze frame available", rows[3].texts[0].toString())
    }

    @Test
    fun detailScreen_contentsUnknownAndReadIncompleteRows() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )

        // Case 1: contentsUnknown
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
                items = listOf(item),
                freezeFrames = listOf(
                    CarFreezeFrame(
                        sourceId = "7E8",
                        frameNumber = 0,
                        causeCode = "P0300",
                        causeKind = CarDtcKind.STORED,
                        causeSourceId = "7E8",
                        readings = emptyList(),
                        undecodableCount = 0,
                        unreadCount = 0,
                        omittedByProjectionCount = 0,
                        contentsUnknown = true,
                    ),
                ),
            ),
        )

        var screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
        )
        var controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        var template = screen.onGetTemplate() as ListTemplate
        var rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Freeze frame contents unreadable", rows[3].texts[0].toString())

        // Case 2: freezeFrameReadIncomplete with no freeze frame
        dtcRepo.submit(
            CarDtcReport(
                schemaVersion = 1,
                reportSequence = 2,
                connectionEpoch = 1,
                phase = CarDtcScanPhase.IDLE,
                verdict = CarDtcVerdict.FAULTS_FOUND,
                coverageComplete = true,
                milOn = true,
                totalCodes = 1,
                freezeFrameReadIncomplete = true,
                items = listOf(item),
                freezeFrames = emptyList(),
            ),
        )
        runCurrent()
        screen = CarDtcDetailScreen(
            carContext = carContext,
            item = item,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
        )
        controller = ScreenController(screen)
        controller.moveToState(Lifecycle.State.RESUMED)

        @Suppress("DEPRECATION")
        template = screen.onGetTemplate() as ListTemplate
        rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals("Incomplete data · Read interrupted", rows[3].texts[0].toString())
    }

    @Test
    fun detailScreen_popsToHealthScreenWhenVehicleStartsMoving() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(sequence = 1, speed = 0.0, epoch = 1))
        val dtcRepo = DefaultCarDtcRepository()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        dtcRepo.submit(
            CarDtcReport(
                schemaVersion = 1,
                reportSequence = 1,
                connectionEpoch = 1,
                phase = CarDtcScanPhase.IDLE,
                verdict = CarDtcVerdict.FAULTS_FOUND,
                coverageComplete = true,
                milOn = false,
                totalCodes = 1,
                freezeFrameReadIncomplete = false,
                items = listOf(item),
                freezeFrames = emptyList(),
            ),
        )

        val healthScreen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
        )
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

        // Vehicle moves
        telemRepo.submit(frameInput(sequence = 2, speed = 25.0, epoch = 1))
        runCurrent()

        assertEquals(healthScreen, screenManager.top)
    }

    @Test
    fun detailScreen_epochMismatchNeverRendersPreviousCarItem() = runTest {
        val telemRepo = createTelemetryRepo()
        telemRepo.submit(frameInput(sequence = 1, epoch = 1, speed = 0.0))
        val dtcRepo = DefaultCarDtcRepository()
        val itemCarA = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
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
                items = listOf(itemCarA),
                freezeFrames = emptyList(),
            ),
        )

        val healthScreen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
        )
        val screenManager = carContext.getCarService(ScreenManager::class.java)
        screenManager.push(healthScreen)

        val detailScreen = CarDtcDetailScreen(
            carContext = carContext,
            item = itemCarA,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        screenManager.push(detailScreen)
        val controller = ScreenController(detailScreen)
        controller.moveToState(Lifecycle.State.RESUMED)

        assertEquals(detailScreen, screenManager.top)

        // Epoch switches to Car B (epoch = 2), Car B is also stationary at 0 km/h
        telemRepo.submit(frameInput(sequence = 2, epoch = 2, speed = 0.0))
        runCurrent()

        // 1. Observer pops back to HealthScreen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() fails closed without rendering Car A's item
        @Suppress("DEPRECATION")
        val template = detailScreen.onGetTemplate() as ListTemplate
        assertEquals("Code Details", template.title?.toString())
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }

    @Test
    fun detailScreen_rescanRemovingSelectedItemDoesNotRenderStaleItem() = runTest {
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
                items = listOf(item),
                freezeFrames = emptyList(),
            ),
        )

        val healthScreen = CarHealthScreen(
            carContext = carContext,
            telemetryRepository = telemRepo,
            dtcRepository = dtcRepo,
        )
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

        // Rescan in the same epoch, but the DTC is now cleared/gone
        dtcRepo.submit(
            CarDtcReport(
                schemaVersion = 1,
                reportSequence = 2,
                connectionEpoch = 1,
                phase = CarDtcScanPhase.IDLE,
                verdict = CarDtcVerdict.COMPLETE_CLEAN,
                coverageComplete = true,
                milOn = false,
                totalCodes = 0,
                freezeFrameReadIncomplete = false,
                items = emptyList(),
                freezeFrames = emptyList(),
            ),
        )
        runCurrent()

        // 1. Observer pops back to HealthScreen
        assertEquals(healthScreen, screenManager.top)

        // 2. Direct onGetTemplate() fails closed without rendering stale item
        @Suppress("DEPRECATION")
        val template = detailScreen.onGetTemplate() as ListTemplate
        assertEquals("Code Details", template.title?.toString())
        val rows = (template.singleList?.items ?: emptyList()).filterIsInstance<androidx.car.app.model.Row>()
        assertEquals(1, rows.size)
        assertEquals("Diagnostics unavailable / incomplete", rows[0].title?.toString())
    }
}

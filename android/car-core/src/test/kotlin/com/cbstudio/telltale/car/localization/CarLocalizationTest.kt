package com.cbstudio.telltale.car.localization

import android.content.res.Configuration
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.CarDtcDetailScreen
import com.cbstudio.telltale.car.CarDtcSummaryScreen
import com.cbstudio.telltale.car.CarHealthScreen
import com.cbstudio.telltale.car.CarHomeScreen
import com.cbstudio.telltale.car.R
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
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.w3c.dom.Element
import java.io.File
import java.text.Bidi
import java.util.Locale
import java.util.regex.Pattern
import javax.xml.parsers.DocumentBuilderFactory

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarLocalizationTest {

    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext(),
        )
    }

    private fun loadStringsXml(file: File): Map<String, String> {
        assertTrue("Resource file must exist: ${file.absolutePath}", file.exists())
        val factory = DocumentBuilderFactory.newInstance()
        val builder = factory.newDocumentBuilder()
        val doc = builder.parse(file)
        val stringNodes = doc.getElementsByTagName("string")
        val result = mutableMapOf<String, String>()
        for (i in 0 until stringNodes.length) {
            val node = stringNodes.item(i) as Element
            val name = node.getAttribute("name")
            val text = node.textContent
            result[name] = text
        }
        return result
    }

    private fun findResDir(): File {
        // Resolve project root from user.dir or class loader
        val candidates = listOf(
            File("android/car-core/src/main/res"),
            File("car-core/src/main/res"),
            File("src/main/res"),
            File("../car-core/src/main/res"),
        )
        return candidates.firstOrNull { it.exists() && it.isDirectory }
            ?: throw IllegalStateException("Could not find car-core/src/main/res")
    }

    @Test
    fun stringsResourceParity_allKeysPresentInLocales() {
        val resDir = findResDir()
        val defaultStrings = loadStringsXml(File(resDir, "values/strings.xml"))
        val zhTwStrings = loadStringsXml(File(resDir, "values-zh-rTW/strings.xml"))
        val zhCnStrings = loadStringsXml(File(resDir, "values-zh-rCN/strings.xml"))

        assertTrue("Default strings must not be empty", defaultStrings.isNotEmpty())
        assertEquals("zh-rTW must match default key count", defaultStrings.size, zhTwStrings.size)
        assertEquals("zh-rCN must match default key count", defaultStrings.size, zhCnStrings.size)

        for ((key, defaultVal) in defaultStrings) {
            assertTrue("Missing key '$key' in values-zh-rTW/strings.xml", zhTwStrings.containsKey(key))
            assertTrue("Missing key '$key' in values-zh-rCN/strings.xml", zhCnStrings.containsKey(key))

            val twVal = zhTwStrings[key]!!
            val cnVal = zhCnStrings[key]!!

            assertFalse("Key '$key' in zh-rTW must not be empty", twVal.isBlank())
            assertFalse("Key '$key' in zh-rCN must not be empty", cnVal.isBlank())

            // Verify format specifiers match
            val formatPattern = Pattern.compile("%(?:\\d+\\$)?[-#+ 0,(]*\\d*(?:\\.\\d+)?[a-zA-Z]")
            val defaultMatchers = formatPattern.matcher(defaultVal).results().map { it.group() }.toList()
            val twMatchers = formatPattern.matcher(twVal).results().map { it.group() }.toList()
            val cnMatchers = formatPattern.matcher(cnVal).results().map { it.group() }.toList()

            assertEquals("Format specifiers in key '$key' mismatch for zh-rTW", defaultMatchers.size, twMatchers.size)
            assertEquals("Format specifiers in key '$key' mismatch for zh-rCN", defaultMatchers.size, cnMatchers.size)
        }
    }

    @Test
    fun safetySemantics_noObservedWarnings_strictlyEnforced() {
        val resDir = findResDir()
        val defaultStrings = loadStringsXml(File(resDir, "values/strings.xml"))
        val zhTwStrings = loadStringsXml(File(resDir, "values-zh-rTW/strings.xml"))
        val zhCnStrings = loadStringsXml(File(resDir, "values-zh-rCN/strings.xml"))

        val defaultWarning = defaultStrings["car_health_status_no_warnings"]
        val twWarning = zhTwStrings["car_health_status_no_warnings"]
        val cnWarning = zhCnStrings["car_health_status_no_warnings"]

        assertEquals("No observed warnings", defaultWarning)
        assertEquals("無觀測到警示", twWarning)
        assertEquals("未观测到警示", cnWarning)

        // Strict safety rule: NEVER claim the entire vehicle or condition is "normal"
        val forbiddenTerms = listOf("車況正常", "车辆正常", "一切正常", "正常")
        for (term in forbiddenTerms) {
            assertFalse("zh-rTW must not claim vehicle is normal: '$term'", twWarning?.contains(term) == true)
            assertFalse("zh-rCN must not claim vehicle is normal: '$term'", cnWarning?.contains(term) == true)
        }
    }

    @Test
    fun isoDtcTerminology_storedPendingPermanent() {
        val resDir = findResDir()
        val defaultStrings = loadStringsXml(File(resDir, "values/strings.xml"))
        val zhTwStrings = loadStringsXml(File(resDir, "values-zh-rTW/strings.xml"))
        val zhCnStrings = loadStringsXml(File(resDir, "values-zh-rCN/strings.xml"))

        // Standard ISO 15031 / SAE J1979 DTC classifications
        assertEquals("Stored", defaultStrings["car_dtc_kind_stored"])
        assertEquals("Pending", defaultStrings["car_dtc_kind_pending"])
        assertEquals("Permanent", defaultStrings["car_dtc_kind_permanent"])

        assertEquals("已儲存", zhTwStrings["car_dtc_kind_stored"])
        assertEquals("待確認", zhTwStrings["car_dtc_kind_pending"])
        assertEquals("永久", zhTwStrings["car_dtc_kind_permanent"])

        assertEquals("已存储", zhCnStrings["car_dtc_kind_stored"])
        assertEquals("待确认", zhCnStrings["car_dtc_kind_pending"])
        assertEquals("永久", zhCnStrings["car_dtc_kind_permanent"])
    }

    @Test
    fun rtlBiDiIsolation_preservesDtcCodeAndMetricSequence() {
        val rawDtc = "P0300"
        val rawVoltage = "13.8 V"

        val isolatedDtc = CarTextIsolation.wrapDtcCode(rawDtc)
        val isolatedVoltage = CarTextIsolation.isolateLtr(rawVoltage)

        assertTrue(CarTextIsolation.isLtrIsolated(isolatedDtc))
        assertTrue(CarTextIsolation.isLtrIsolated(isolatedVoltage))

        assertEquals(rawDtc, CarTextIsolation.stripIsolation(isolatedDtc))
        assertEquals(rawVoltage, CarTextIsolation.stripIsolation(isolatedVoltage))

        // Embed inside an Arabic RTL sentence: "رمز العطل: [P0300]"
        val rtlPrefix = "\u0631\u0645\u0632 \u0627\u0644\u0639\u0637\u0644: "
        val mixedRtlText = "$rtlPrefix$isolatedDtc"

        // Analyze BiDi structure
        val bidi = Bidi(mixedRtlText, Bidi.DIRECTION_DEFAULT_RIGHT_TO_LEFT)
        assertFalse("Base direction should be RTL (baseIsLeftToRight should be false)", bidi.baseIsLeftToRight())
        assertTrue("Paragraph containing both Arabic RTL text and isolated LTR code should be mixed", bidi.isMixed)

        // Find the run corresponding to the isolated text
        val isolatedStart = mixedRtlText.indexOf(CarTextIsolation.LEFT_TO_RIGHT_ISOLATE)
        assertTrue(isolatedStart >= 0)

        // Check that character sequence of P0300 is preserved exactly
        val extractedInner = mixedRtlText.substring(isolatedStart + 1, isolatedStart + 1 + rawDtc.length)
        assertEquals("P0300", extractedInner)
    }

    @Test
    fun localizedCarContext_loadsExpectedValues() {
        val app = ApplicationProvider.getApplicationContext<android.content.Context>()

        // 1. Traditional Chinese (Taiwan)
        val twConfig = Configuration(app.resources.configuration)
        twConfig.setLocale(Locale.TAIWAN)
        val twContext = app.createConfigurationContext(twConfig)
        val twNoWarnings = twContext.getString(R.string.car_health_status_no_warnings)
        val twStored = twContext.getString(R.string.car_dtc_kind_stored)
        assertEquals("無觀測到警示", twNoWarnings)
        assertEquals("已儲存", twStored)

        // 2. Simplified Chinese (China)
        val cnConfig = Configuration(app.resources.configuration)
        cnConfig.setLocale(Locale.SIMPLIFIED_CHINESE)
        val cnContext = app.createConfigurationContext(cnConfig)
        val cnNoWarnings = cnContext.getString(R.string.car_health_status_no_warnings)
        val cnStored = cnContext.getString(R.string.car_dtc_kind_stored)
        assertEquals("未观测到警示", cnNoWarnings)
        assertEquals("已存储", cnStored)
    }

    @Test
    fun screenLevel_dtcSummaryScreen_rendersLocalizedAndIsolated_inRtlAndLtr() = runTest {
        val app = ApplicationProvider.getApplicationContext<android.content.Context>()
        val item = CarDtcItem(
            code = "P0300",
            kind = CarDtcKind.STORED,
            sourceId = "7E8",
            isManufacturerSpecific = false,
            completeness = CarDtcCompleteness.COMPLETE,
        )
        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { 0L },
        )
        telemRepo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = CarSignalInput(CarSignalStatus.LIVE, 0.0),
                rpm = CarSignalInput(CarSignalStatus.LIVE, 800.0),
                coolantC = CarSignalInput(CarSignalStatus.LIVE, 90.0),
                intakeAirC = CarSignalInput(CarSignalStatus.LIVE, 25.0),
                controlModuleVoltageV = CarSignalInput(CarSignalStatus.LIVE, 13.8),
                mapKpa = CarSignalInput(CarSignalStatus.LIVE, 35.0),
                diagnosticsAvailable = true,
                milOn = true,
                dtcCount = 1,
            )
        )
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
                items = listOf(item),
                freezeFrames = emptyList(),
            )
        )

        // 1. Standard LTR (US English)
        val ltrCarContext = TestCarContext.createCarContext(app)
        val ltrScreen = CarDtcSummaryScreen(ltrCarContext, telemRepo, dtcRepo)
        val ltrController = ScreenController(ltrScreen)
        ltrController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val ltrTemplate = ltrScreen.onGetTemplate() as ListTemplate
        val ltrRows = (ltrTemplate.singleList?.items ?: emptyList()).filterIsInstance<Row>()
        assertEquals(1, ltrRows.size)
        assertEquals("P0300 · Stored", ltrRows[0].title?.toString())
        assertEquals("Controller 7E8", ltrRows[0].texts[0].toString())

        // 2. Traditional Chinese (zh-TW)
        val twConfig = Configuration(app.resources.configuration)
        twConfig.setLocale(Locale.TAIWAN)
        val twAppContext = app.createConfigurationContext(twConfig)
        val twCarContext = TestCarContext.createCarContext(twAppContext)
        val twScreen = CarDtcSummaryScreen(twCarContext, telemRepo, dtcRepo)
        val twController = ScreenController(twScreen)
        twController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val twTemplate = twScreen.onGetTemplate() as ListTemplate
        val twRows = (twTemplate.singleList?.items ?: emptyList()).filterIsInstance<Row>()
        assertEquals(1, twRows.size)
        assertEquals("P0300 · 已儲存", twRows[0].title?.toString())
        assertEquals("控制器 7E8", twRows[0].texts[0].toString())

        // 3. Right-to-Left (RTL) Layout
        val rtlConfig = Configuration(app.resources.configuration)
        rtlConfig.setLayoutDirection(Locale("ar"))
        rtlConfig.setLocale(Locale("ar"))
        val rtlAppContext = app.createConfigurationContext(rtlConfig)
        val rtlCarContext = TestCarContext.createCarContext(rtlAppContext)
        val rtlScreen = CarDtcSummaryScreen(rtlCarContext, telemRepo, dtcRepo)
        val rtlController = ScreenController(rtlScreen)
        rtlController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val rtlTemplate = rtlScreen.onGetTemplate() as ListTemplate
        val rtlRows = (rtlTemplate.singleList?.items ?: emptyList()).filterIsInstance<Row>()
        assertEquals(1, rtlRows.size)
        val rtlTitle = rtlRows[0].title?.toString() ?: ""
        assertTrue("RTL title must contain LTR isolate start marker", rtlTitle.contains(CarTextIsolation.LEFT_TO_RIGHT_ISOLATE))
        assertTrue("RTL title must contain LTR isolate pop marker", rtlTitle.contains(CarTextIsolation.POP_DIRECTIONAL_ISOLATE))
        assertTrue("RTL title must embed isolated P0300", rtlTitle.contains("${CarTextIsolation.LEFT_TO_RIGHT_ISOLATE}P0300${CarTextIsolation.POP_DIRECTIONAL_ISOLATE}"))
    }

    @Test
    fun screenLevel_homeScreen_rendersMetricWithRtlIsolation_inRtlAndLtr() = runTest {
        val app = ApplicationProvider.getApplicationContext<android.content.Context>()
        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { 0L },
        )
        telemRepo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = CarSignalInput(CarSignalStatus.LIVE, 45.0),
                rpm = CarSignalInput(CarSignalStatus.LIVE, 1800.0),
                coolantC = CarSignalInput(CarSignalStatus.LIVE, 90.0),
                intakeAirC = CarSignalInput(CarSignalStatus.LIVE, 25.0),
                controlModuleVoltageV = CarSignalInput(CarSignalStatus.LIVE, 13.8),
                mapKpa = CarSignalInput(CarSignalStatus.LIVE, 35.0),
                diagnosticsAvailable = false,
                milOn = null,
                dtcCount = null,
            )
        )

        // 1. Standard LTR (US English)
        val ltrCarContext = TestCarContext.createCarContext(app)
        val ltrScreen = CarHomeScreen(ltrCarContext, telemRepo)
        val ltrController = ScreenController(ltrScreen)
        ltrController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val ltrTemplate = ltrScreen.onGetTemplate() as PaneTemplate
        val ltrSpeedText = ltrTemplate.pane.rows[0].texts[0].toString()
        assertEquals("45 km/h", ltrSpeedText)

        // 2. Right-to-Left (RTL) Layout
        val rtlConfig = Configuration(app.resources.configuration)
        rtlConfig.setLayoutDirection(Locale("ar"))
        rtlConfig.setLocale(Locale("ar"))
        val rtlAppContext = app.createConfigurationContext(rtlConfig)
        val rtlCarContext = TestCarContext.createCarContext(rtlAppContext)
        val rtlScreen = CarHomeScreen(rtlCarContext, telemRepo)
        val rtlController = ScreenController(rtlScreen)
        rtlController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val rtlTemplate = rtlScreen.onGetTemplate() as PaneTemplate
        val rtlSpeedText = rtlTemplate.pane.rows[0].texts[0].toString()
        assertTrue("RTL speed text must be LTR isolated", CarTextIsolation.isLtrIsolated(rtlSpeedText))
        assertEquals("${CarTextIsolation.LEFT_TO_RIGHT_ISOLATE}45 km/h${CarTextIsolation.POP_DIRECTIONAL_ISOLATE}", rtlSpeedText)
    }

    @Test
    fun isRtlContext_rootLocaleAndEmptyDisplayName_neverThrowsAndReturnsFalse() {
        val origLocale = Locale.getDefault()
        try {
            Locale.setDefault(Locale.ROOT)
            assertFalse(CarTextIsolation.isRtlContext(null))
        } finally {
            Locale.setDefault(origLocale)
        }
    }

    @Test
    fun screenLevelRtlIsolation_carHealthScreen_isolatesCoolantAndVoltageMetrics() = runTest {
        val app = ApplicationProvider.getApplicationContext<android.content.Context>()
        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { 0L },
        )
        telemRepo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = CarSignalInput(CarSignalStatus.LIVE, 45.0),
                rpm = CarSignalInput(CarSignalStatus.LIVE, 1800.0),
                coolantC = CarSignalInput(CarSignalStatus.LIVE, 90.0),
                intakeAirC = CarSignalInput(CarSignalStatus.LIVE, 25.0),
                controlModuleVoltageV = CarSignalInput(CarSignalStatus.LIVE, 13.8),
                mapKpa = CarSignalInput(CarSignalStatus.LIVE, 35.0),
                diagnosticsAvailable = true,
                milOn = false,
                dtcCount = 0L,
            ),
        )

        // 1. Standard LTR (US English)
        val ltrCarContext = TestCarContext.createCarContext(app)
        val ltrScreen = CarHealthScreen(ltrCarContext, telemRepo, contentLimitProvider = { 6 })
        val ltrController = ScreenController(ltrScreen)
        ltrController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val ltrTemplate = ltrScreen.onGetTemplate() as PaneTemplate
        val ltrCoolant = ltrTemplate.pane.rows[3].texts[0].toString()
        val ltrVoltage = ltrTemplate.pane.rows[4].texts[0].toString()
        assertEquals("90 °C", ltrCoolant)
        assertEquals("13.8 V", ltrVoltage)

        // 2. Right-to-Left (RTL) Layout
        val rtlConfig = Configuration(app.resources.configuration)
        rtlConfig.setLayoutDirection(Locale("ar"))
        rtlConfig.setLocale(Locale("ar"))
        val rtlAppContext = app.createConfigurationContext(rtlConfig)
        val rtlCarContext = TestCarContext.createCarContext(rtlAppContext)
        val rtlScreen = CarHealthScreen(rtlCarContext, telemRepo, contentLimitProvider = { 6 })
        val rtlController = ScreenController(rtlScreen)
        rtlController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val rtlTemplate = rtlScreen.onGetTemplate() as PaneTemplate
        val rtlCoolant = rtlTemplate.pane.rows[3].texts[0].toString()
        val rtlVoltage = rtlTemplate.pane.rows[4].texts[0].toString()

        assertTrue("RTL coolant must be LTR isolated", CarTextIsolation.isLtrIsolated(rtlCoolant))
        assertTrue("RTL voltage must be LTR isolated", CarTextIsolation.isLtrIsolated(rtlVoltage))
        assertEquals("${CarTextIsolation.LEFT_TO_RIGHT_ISOLATE}90 °C${CarTextIsolation.POP_DIRECTIONAL_ISOLATE}", rtlCoolant)
        assertEquals("${CarTextIsolation.LEFT_TO_RIGHT_ISOLATE}13.8 V${CarTextIsolation.POP_DIRECTIONAL_ISOLATE}", rtlVoltage)
    }

    @Test
    fun screenLevelRtlIsolation_carDtcDetailScreen_isolatesFreezeFrameMetrics() = runTest {
        val app = ApplicationProvider.getApplicationContext<android.content.Context>()
        val telemRepo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { 0L },
        )
        val dtcRepo = DefaultCarDtcRepository()
        val targetItem = CarDtcItem("P0300", CarDtcKind.STORED, "7E8", false, CarDtcCompleteness.COMPLETE)

        telemRepo.submit(
            CarTelemetryFrameInput(
                schemaVersion = 1,
                sequence = 1,
                connectionEpoch = 1,
                lifecycleEpoch = 0,
                producedAtMonotonicUs = 1_000,
                connectionPhase = CarConnectionPhase.CONNECTED,
                speedKmh = CarSignalInput(CarSignalStatus.LIVE, 0.0),
                rpm = CarSignalInput(CarSignalStatus.LIVE, 800.0),
                coolantC = CarSignalInput(CarSignalStatus.LIVE, 90.0),
                intakeAirC = CarSignalInput(CarSignalStatus.LIVE, 25.0),
                controlModuleVoltageV = CarSignalInput(CarSignalStatus.LIVE, 13.8),
                mapKpa = CarSignalInput(CarSignalStatus.LIVE, 35.0),
                diagnosticsAvailable = true,
                milOn = true,
                dtcCount = 1L,
            ),
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
                items = listOf(targetItem),
                freezeFrames = listOf(
                    CarFreezeFrame(
                        sourceId = "7E8",
                        frameNumber = 0,
                        causeCode = "P0300",
                        causeKind = CarDtcKind.STORED,
                        causeSourceId = "7E8",
                        readings = listOf(
                            CarFreezeReading(
                                CarFreezeSignalKind.CONTROL_MODULE_VOLTAGE_V,
                                13.8,
                            ),
                        ),
                        undecodableCount = 0,
                        unreadCount = 0,
                        omittedByProjectionCount = 0,
                        contentsUnknown = false,
                    ),
                ),
            ),
        )

        // Right-to-Left (RTL) Layout
        val rtlConfig = Configuration(app.resources.configuration)
        rtlConfig.setLayoutDirection(Locale("ar"))
        rtlConfig.setLocale(Locale("ar"))
        val rtlAppContext = app.createConfigurationContext(rtlConfig)
        val rtlCarContext = TestCarContext.createCarContext(rtlAppContext)
        val rtlScreen = CarDtcDetailScreen(
            carContext = rtlCarContext,
            item = targetItem,
            dtcRepository = dtcRepo,
            telemetryRepository = telemRepo,
            coroutineScope = backgroundScope,
        )
        val rtlController = ScreenController(rtlScreen)
        rtlController.moveToState(Lifecycle.State.RESUMED)
        @Suppress("DEPRECATION")
        val rtlTemplate = rtlScreen.onGetTemplate() as ListTemplate
        val list = rtlTemplate.singleList!!
        // Rows: 0: Class, 1: Controller, 2: Coverage, 3: Freeze Frame Voltage
        val ffRow = list.items[3] as Row
        val voltageText = ffRow.texts[0].toString()
        assertTrue("RTL freeze frame voltage must be LTR isolated", CarTextIsolation.isLtrIsolated(voltageText))
        assertEquals("${CarTextIsolation.LEFT_TO_RIGHT_ISOLATE}13.8 V${CarTextIsolation.POP_DIRECTIONAL_ISOLATE}", voltageText)
    }
}

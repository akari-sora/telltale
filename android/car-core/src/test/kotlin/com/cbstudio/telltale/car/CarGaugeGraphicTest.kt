package com.cbstudio.telltale.car

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.drawable.Icon
import androidx.car.app.model.CarIcon
import androidx.car.app.model.GridItem
import androidx.car.app.testing.TestCarContext
import androidx.test.core.app.ApplicationProvider
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CarGaugeGraphicTest {

    private lateinit var graphic: CarGaugeGraphic

    @Before
    fun setUp() {
        graphic = CarGaugeGraphic(
            TestCarContext.createCarContext(ApplicationProvider.getApplicationContext()),
        )
    }

    private fun live(
        value: Double,
        metric: CarMetricIcon = CarMetricIcon.SPEED,
        reading: String = format(metric, value),
        warning: Boolean = false,
        dark: Boolean = true,
    ): CarIcon = graphic.icon(metric, value, reading, CarGaugeState.LIVE, warning, dark)

    private fun empty(
        state: CarGaugeState,
        metric: CarMetricIcon = CarMetricIcon.SPEED,
        warning: Boolean = false,
        dark: Boolean = true,
    ): CarIcon = graphic.icon(metric, null, null, state, warning, dark)

    private fun format(metric: CarMetricIcon, value: Double): String =
        if (metric == CarMetricIcon.VOLTAGE) "%.1f".format(java.util.Locale.US, value) else "%.0f".format(java.util.Locale.US, value)

    private fun CarIcon.bitmap(): Bitmap {
        val compat = requireNotNull(icon)
        assertEquals(Icon.TYPE_BITMAP, compat.type)
        return requireNotNull(compat.bitmap)
    }

    /** Pixels in a box, so layout tweaks do not break the tests but drawing a numeral does. */
    private fun Bitmap.differingPixels(other: Bitmap, left: Int, top: Int, right: Int, bottom: Int): Int {
        val s = width / 128f
        var count = 0
        for (y in (top * s).toInt() until (bottom * s).toInt()) {
            for (x in (left * s).toInt() until (right * s).toInt()) {
                if (getPixel(x, y) != other.getPixel(x, y)) count++
            }
        }
        return count
    }

    @Test
    fun bitmap_hasFixedArgbSizeAtMdpiAndCanBeUsedAsLargeGridImage() {
        val carIcon = live(120.0)
        val bitmap = carIcon.bitmap()
        assertEquals(128, bitmap.width)
        assertEquals(128, bitmap.height)
        assertEquals(Bitmap.Config.ARGB_8888, bitmap.config)
        assertEquals(0, bitmap.getPixel(0, 0)) // Transparent corners retain the round instrument shape.
        val item = GridItem.Builder()
            .setTitle("Speed")
            .setText("120 km/h")
            .setImage(carIcon, GridItem.IMAGE_TYPE_LARGE)
            .build()
        assertEquals(GridItem.IMAGE_TYPE_LARGE, item.imageType)
        assertSame(carIcon, item.image)
        assertEquals("120 km/h", item.text?.toString())
    }

    @Test
    @Config(qualifiers = "xhdpi")
    fun bitmap_targetsTheCarScreenDensity() {
        val bitmap = live(120.0).bitmap()
        assertEquals(256, bitmap.width)
        assertEquals(256, bitmap.height)
    }

    @Test
    @Config(qualifiers = "xxxhdpi")
    fun bitmap_sizeIsCappedForHighDensityScreens() {
        val bitmap = live(120.0).bitmap()
        assertEquals(320, bitmap.width)
        assertEquals(320, bitmap.height)
    }

    @Test
    fun liveReadingDrawsANumeralButMissingStaleAndUnsupportedNeverDo() {
        val missing = empty(CarGaugeState.NO_DATA).bitmap()
        val stale = empty(CarGaugeState.STALE).bitmap()
        val unsupported = empty(CarGaugeState.UNSUPPORTED).bitmap()
        val zero = live(0.0).bitmap()
        val fortyEight = live(48.0).bitmap()
        // The numeral area changes with the reading.
        assertTrue(zero.differingPixels(fortyEight, 30, 52, 98, 82) > 50)
        // Missing, stale and unsupported share the same placeholder numeral, unlike a real zero.
        assertEquals(0, missing.differingPixels(stale, 30, 52, 98, 82))
        assertEquals(0, missing.differingPixels(unsupported, 30, 52, 98, 82))
        assertTrue(missing.differingPixels(zero, 30, 52, 98, 82) > 50)
        // But each state stays distinguishable elsewhere (stale track pattern, unsupported glyph).
        assertFalse(missing.sameAs(stale))
        assertFalse(missing.sameAs(unsupported))
        assertFalse(stale.sameAs(unsupported))
    }

    @Test
    fun liveWithoutAFiniteValueOrReadingIsDrawnAsMissing() {
        val missing = empty(CarGaugeState.NO_DATA)
        listOf(Double.NaN, Double.POSITIVE_INFINITY, Double.NEGATIVE_INFINITY).forEach {
            assertSame(missing, graphic.icon(CarMetricIcon.SPEED, it, "1", CarGaugeState.LIVE, false, true))
        }
        assertSame(missing, graphic.icon(CarMetricIcon.SPEED, null, "1", CarGaugeState.LIVE, false, true))
        assertSame(missing, graphic.icon(CarMetricIcon.SPEED, 10.0, null, CarGaugeState.LIVE, false, true))
        // Stale input never draws a remembered value even if one is passed by mistake.
        assertSame(
            empty(CarGaugeState.STALE),
            graphic.icon(CarMetricIcon.SPEED, 42.0, "42", CarGaugeState.STALE, false, true),
        )
    }

    @Test
    fun finiteZero_usesTheMetricVisualRange() {
        assertFalse(empty(CarGaugeState.NO_DATA).bitmap().sameAs(live(0.0).bitmap()))
        // Zero Celsius is above the temperature scale's -40 minimum, so it has a real value arc.
        assertFalse(
            empty(CarGaugeState.NO_DATA, CarMetricIcon.TEMPERATURE).bitmap()
                .sameAs(live(0.0, CarMetricIcon.TEMPERATURE).bitmap()),
        )
    }

    @Test
    fun outOfRangeValues_clampOnlyTheArcAndKeepTheirOwnReading() {
        val limits = listOf(
            Triple(CarMetricIcon.SPEED, 0.0, 240.0),
            Triple(CarMetricIcon.RPM, 0.0, 8_000.0),
            Triple(CarMetricIcon.TEMPERATURE, -40.0, 215.0),
            Triple(CarMetricIcon.VOLTAGE, 0.0, 24.0),
        )
        limits.forEach { (metric, min, max) ->
            val atMax = live(max, metric).bitmap()
            val beyondMax = live(max + 100.0, metric).bitmap()
            // Same arc and glyph above the numeral, different numeral.
            assertEquals(0, atMax.differingPixels(beyondMax, 0, 0, 128, 44))
            assertFalse(atMax.sameAs(beyondMax))
            assertFalse(live(min, metric).bitmap().sameAs(atMax))
            // Identical arguments reuse the cached image.
            assertSame(live(max + 100.0, metric), live(max + 100.0, metric))
        }
    }

    @Test
    fun themeAndWarning_changePixelsAndWarningAddsAShapeNotOnlyAColour() {
        val normalDark = live(120.0).bitmap()
        val normalLight = live(120.0, dark = false).bitmap()
        val warningDark = live(120.0, warning = true).bitmap()
        val warningLight = live(120.0, warning = true, dark = false).bitmap()
        assertFalse(normalDark.sameAs(normalLight))
        assertFalse(normalDark.sameAs(warningDark))
        assertFalse(normalLight.sameAs(warningLight))
        // The status glyph above the numeral turns into a warning triangle, also without a reading.
        val absent = empty(CarGaugeState.NO_DATA).bitmap()
        val absentWarning = empty(CarGaugeState.NO_DATA, warning = true).bitmap()
        assertTrue(absent.differingPixels(absentWarning, 52, 26, 76, 48) > 40)
        // Shape check in greyscale: the triangle's luminance pattern differs from the metric glyph's.
        assertTrue(greyDiff(absent, absentWarning, 52, 26, 76, 48) > 40)
    }

    private fun greyDiff(a: Bitmap, b: Bitmap, left: Int, top: Int, right: Int, bottom: Int): Int {
        fun luma(c: Int) = (Color.red(c) * 299 + Color.green(c) * 587 + Color.blue(c) * 114) / 1000
        var count = 0
        for (y in top until bottom) for (x in left until right) {
            if (kotlin.math.abs(luma(a.getPixel(x, y)) - luma(b.getPixel(x, y))) > 40) count++
        }
        return count
    }

    @Test
    fun dayAndNightPalettesKeepADarkFaceButNightIsDimmer() {
        fun faceLuma(bitmap: Bitmap): Int {
            val c = bitmap.getPixel(64, 118) // Face below the scale labels.
            return (Color.red(c) * 299 + Color.green(c) * 587 + Color.blue(c) * 114) / 1000
        }
        val day = empty(CarGaugeState.NO_DATA, dark = false).bitmap()
        val night = empty(CarGaugeState.NO_DATA, dark = true).bitmap()
        assertTrue(faceLuma(day) < 64)
        assertTrue(faceLuma(night) < faceLuma(day))
    }

    @Test
    fun coolantShowsTheExistingAlertRegionAndOtherMetricsInventNone() {
        // The region comes from CarAlertPolicy.DEFAULT_COOLANT; only the temperature gauge has it.
        val coolant = empty(CarGaugeState.NO_DATA, CarMetricIcon.TEMPERATURE).bitmap()
        val band = coolant.getPixel(124, 64) // On the band, at the 3 o'clock position (~150 °C).
        val warm = Color.red(band) - Color.blue(band)
        assertTrue("Expected a warm hatched band on the coolant scale, was $warm", warm > 60)
        listOf(CarMetricIcon.SPEED, CarMetricIcon.RPM, CarMetricIcon.VOLTAGE).forEach { metric ->
            val bitmap = empty(CarGaugeState.NO_DATA, metric).bitmap()
            for (y in 0 until 128) for (x in 0 until 128) {
                val c = bitmap.getPixel(x, y)
                assertTrue("$metric has a warm pixel at $x,$y", Color.red(c) - Color.blue(c) < 40)
            }
        }
    }

    @Test
    fun cache_reusesRecentImagesAndEvictsLeastRecentlyUsedAfterEightEntries() {
        val oldest = live(1.0)
        val accessed = live(2.0)
        (3..8).forEach { live(it.toDouble()) }
        assertSame(accessed, live(2.0))
        live(9.0)
        assertSame(accessed, live(2.0))
        assertNotSame(oldest, live(1.0))
    }

    @Test(expected = IllegalArgumentException::class)
    fun unsupportedMetrics_doNotInventAGaugeScale() {
        live(50.0, CarMetricIcon.PRESSURE)
    }

    /**
     * Renders every gauge state for review. Always asserts that the states are distinct; writes
     * PNG files only when TELLTALE_GAUGE_DUMP_DIR is set.
     */
    @Test
    fun everyStateRendersDistinctImages_andCanBeExportedForReview() {
        val dumpDir = System.getenv("TELLTALE_GAUGE_DUMP_DIR")?.takeIf { it.isNotBlank() }?.let(::File)
        dumpDir?.mkdirs()
        val samples = mapOf(
            CarMetricIcon.SPEED to 48.0,
            CarMetricIcon.RPM to 1800.0,
            CarMetricIcon.TEMPERATURE to 108.0,
            CarMetricIcon.VOLTAGE to 14.1,
        )
        var rendered = 0
        val byState = mutableMapOf<String, Bitmap>()
        listOf(false, true).forEach { dark ->
            val theme = if (dark) "night" else "day"
            samples.forEach { (metric, value) ->
                val states = mutableListOf<Bitmap>()
                val name = metric.name.lowercase()
                val cases = linkedMapOf(
                    "normal" to live(value, metric, dark = dark),
                    "zero" to live(if (metric == CarMetricIcon.TEMPERATURE) -40.0 else 0.0, metric, dark = dark),
                    "warning" to live(value, metric, warning = true, dark = dark),
                    "missing" to empty(CarGaugeState.NO_DATA, metric, dark = dark),
                    "stale" to empty(CarGaugeState.STALE, metric, dark = dark),
                    "unsupported" to empty(CarGaugeState.UNSUPPORTED, metric, dark = dark),
                    "warning-stale" to empty(CarGaugeState.STALE, metric, warning = true, dark = dark),
                )
                cases.forEach { (state, icon) ->
                    val bitmap = icon.bitmap()
                    // Every state of one metric looks different, and day differs from night.
                    states.forEach { assertFalse("$theme/$name/$state duplicates another state", it.sameAs(bitmap)) }
                    states += bitmap
                    byState["$name/$state"]?.let { day ->
                        assertFalse("$name/$state is identical by day and night", day.sameAs(bitmap))
                    } ?: byState.put("$name/$state", bitmap)
                    rendered++
                    dumpDir?.let { dir ->
                        File(dir, "$theme-$name-$state.png").outputStream().use {
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                        }
                    }
                }
            }
        }
        assertEquals(2 * 4 * 7, rendered)
    }
}

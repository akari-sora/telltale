package com.cbstudio.telltale.car

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.drawable.Icon
import androidx.car.app.model.CarIcon
import androidx.car.app.model.Pane
import androidx.car.app.model.Row
import androidx.car.app.testing.TestCarContext
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
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

    private fun format(metric: CarMetricIcon, value: Double): String =
        if (metric == CarMetricIcon.VOLTAGE) "%.1f".format(Locale.US, value) else "%.0f".format(Locale.US, value)

    private fun live(metric: CarMetricIcon, value: Double, warning: Boolean = false) =
        CarGaugeReadout(metric, value, format(metric, value), CarGaugeState.LIVE, warning)

    private fun empty(metric: CarMetricIcon, state: CarGaugeState, warning: Boolean = false) =
        CarGaugeReadout(metric, null, null, state, warning)

    private fun pair(first: CarGaugeReadout, second: CarGaugeReadout = live(CarMetricIcon.RPM, 1800.0)) =
        listOf(first, second)

    private fun image(readouts: List<CarGaugeReadout>, dark: Boolean = false): Bitmap =
        requireNotNull(graphic.dashboard(readouts, dark)).bitmap()

    private fun CarIcon.bitmap(): Bitmap {
        val compat = requireNotNull(icon)
        assertEquals(Icon.TYPE_BITMAP, compat.type)
        return requireNotNull(compat.bitmap)
    }

    /** Differing pixels inside a box given in the image's 480-unit space. */
    private fun Bitmap.diff(other: Bitmap, left: Int, top: Int, right: Int, bottom: Int): Int {
        val s = width / 480f
        var count = 0
        for (y in (top * s).toInt() until (bottom * s).toInt()) {
            for (x in (left * s).toInt() until (right * s).toInt()) {
                if (getPixel(x, y) != other.getPixel(x, y)) count++
            }
        }
        return count
    }

    private fun luma(c: Int) = (Color.red(c) * 299 + Color.green(c) * 587 + Color.blue(c) * 114) / 1000

    // Top readout regions (480-unit space): marker/unit line and numeral line.
    private val labelBox = intArrayOf(120, 40, 360, 100)
    private val numeralBox = intArrayOf(90, 104, 390, 216)

    private fun Bitmap.diffIn(other: Bitmap, box: IntArray) = diff(other, box[0], box[1], box[2], box[3])

    @Test
    fun imageIsASquareArgbBitmapAtMdpiThatAPaneAccepts() {
        val icon = requireNotNull(graphic.dashboard(pair(live(CarMetricIcon.SPEED, 120.0)), dark = false))
        val bitmap = icon.bitmap()
        assertEquals(320, bitmap.width)
        assertEquals(320, bitmap.height)
        assertEquals(Bitmap.Config.ARGB_8888, bitmap.config)
        assertEquals(0, bitmap.getPixel(0, 0)) // Rounded panels leave transparent corners.
        val pane = Pane.Builder()
            .addRow(Row.Builder().setTitle("Speed").addText("120 km/h").build())
            .setImage(icon)
            .build()
        assertSame(icon, pane.image)
    }

    @Test
    @Config(qualifiers = "hdpi")
    fun imageTargetsTheCarScreenDensity() {
        assertEquals(480, image(pair(live(CarMetricIcon.SPEED, 120.0))).width)
    }

    @Test
    @Config(qualifiers = "xxxhdpi")
    fun imageSizeIsCappedForHighDensityScreens() {
        assertEquals(640, image(pair(live(CarMetricIcon.SPEED, 120.0))).width)
    }

    @Test
    fun onlyTheFirstTwoReadoutsAreDrawn() {
        val two = image(pair(live(CarMetricIcon.SPEED, 50.0)))
        val four = image(
            pair(live(CarMetricIcon.SPEED, 50.0)) +
                listOf(live(CarMetricIcon.TEMPERATURE, 120.0, warning = true), live(CarMetricIcon.VOLTAGE, 12.0)),
        )
        assertTrue(two.sameAs(four))
    }

    @Test
    fun liveReadingDrawsANumeralButMissingStaleAndUnsupportedNeverDo() {
        val missing = image(pair(empty(CarMetricIcon.SPEED, CarGaugeState.NO_DATA)))
        val stale = image(pair(empty(CarMetricIcon.SPEED, CarGaugeState.STALE)))
        val unsupported = image(pair(empty(CarMetricIcon.SPEED, CarGaugeState.UNSUPPORTED)))
        val zero = image(pair(live(CarMetricIcon.SPEED, 0.0)))
        val busy = image(pair(live(CarMetricIcon.SPEED, 188.0)))
        assertTrue(zero.diffIn(busy, numeralBox) > 200)
        // Missing, stale and unsupported share the same placeholder, unlike a real zero.
        assertEquals(0, missing.diffIn(stale, numeralBox))
        assertEquals(0, missing.diffIn(unsupported, numeralBox))
        assertTrue(missing.diffIn(zero, numeralBox) > 200)
        // Their markers differ: none, clock, prohibition sign.
        assertTrue(missing.diffIn(stale, labelBox) > 50)
        assertTrue(missing.diffIn(unsupported, labelBox) > 50)
        assertTrue(stale.diffIn(unsupported, labelBox) > 50)
    }

    @Test
    fun liveWithoutAFiniteValueOrReadingIsDrawnAsMissing() {
        val missing = image(pair(empty(CarMetricIcon.SPEED, CarGaugeState.NO_DATA)))
        listOf(Double.NaN, Double.POSITIVE_INFINITY, Double.NEGATIVE_INFINITY, null).forEach {
            val corrupt = CarGaugeReadout(CarMetricIcon.SPEED, it, "1", CarGaugeState.LIVE, false)
            assertTrue(missing.sameAs(image(pair(corrupt))))
        }
        val noText = CarGaugeReadout(CarMetricIcon.SPEED, 10.0, null, CarGaugeState.LIVE, false)
        assertTrue(missing.sameAs(image(pair(noText))))
        // A stale readout never draws a remembered value even if one is passed by mistake.
        val staleWithValue = CarGaugeReadout(CarMetricIcon.SPEED, 42.0, "42", CarGaugeState.STALE, false)
        assertTrue(image(pair(empty(CarMetricIcon.SPEED, CarGaugeState.STALE))).sameAs(image(pair(staleWithValue))))
    }

    @Test
    fun outOfRangeValuesClampOnlyTheArcAndKeepTheirOwnReading() {
        listOf(
            Triple(CarMetricIcon.SPEED, 0.0, 240.0),
            Triple(CarMetricIcon.RPM, 0.0, 8_000.0),
            Triple(CarMetricIcon.TEMPERATURE, -40.0, 215.0),
            Triple(CarMetricIcon.VOLTAGE, 0.0, 24.0),
        ).forEach { (metric, min, max) ->
            val atMax = image(pair(live(metric, max)))
            val beyond = image(pair(live(metric, max + 100.0)))
            assertFalse("$metric numeral must change", atMax.diffIn(beyond, numeralBox) == 0)
            // Same arc: the upper corners of the half-circle are identical.
            assertEquals(0, atMax.diff(beyond, 0, 0, 110, 100))
            assertEquals(0, atMax.diff(beyond, 370, 0, 480, 100))
            assertFalse(image(pair(live(metric, min))).sameAs(atMax))
        }
    }

    @Test
    fun warningAddsAFrameAndTriangleNotOnlyColour() {
        val normal = image(pair(live(CarMetricIcon.TEMPERATURE, 108.0)))
        val warning = image(pair(live(CarMetricIcon.TEMPERATURE, 108.0, warning = true)))
        val emptyWarning = image(pair(empty(CarMetricIcon.TEMPERATURE, CarGaugeState.NO_DATA, warning = true)))
        val empty = image(pair(empty(CarMetricIcon.TEMPERATURE, CarGaugeState.NO_DATA)))
        // Greyscale: the triangle and frame change luminance, so they read without colour.
        fun greyDiff(a: Bitmap, b: Bitmap, box: IntArray): Int {
            val s = a.width / 480f
            var n = 0
            for (y in (box[1] * s).toInt() until (box[3] * s).toInt()) for (x in (box[0] * s).toInt() until (box[2] * s).toInt()) {
                if (kotlin.math.abs(luma(a.getPixel(x, y)) - luma(b.getPixel(x, y))) > 40) n++
            }
            return n
        }
        assertTrue(greyDiff(normal, warning, labelBox) > 40)
        assertTrue(greyDiff(empty, emptyWarning, labelBox) > 40)
        assertTrue(greyDiff(empty, emptyWarning, intArrayOf(0, 0, 480, 12)) > 40) // Frame along the top edge.
    }

    @Test
    fun dayAndNightPalettesDifferAndNightIsDimmer() {
        val readouts = pair(live(CarMetricIcon.SPEED, 88.0))
        val day = image(readouts, dark = false)
        val night = image(readouts, dark = true)
        assertFalse(day.sameAs(night))
        val s = day.width / 480f
        val panel = ((240 * s).toInt() to (228 * s).toInt()) // Inside the panel, below the numeral.
        assertTrue(luma(night.getPixel(panel.first, panel.second)) < luma(day.getPixel(panel.first, panel.second)))
        assertTrue(luma(day.getPixel(panel.first, panel.second)) < 64) // Dark panel in both modes.
    }

    @Test
    fun coolantShowsTheExistingAlertRegionAndOtherMetricsInventNone() {
        val coolant = image(pair(empty(CarMetricIcon.TEMPERATURE, CarGaugeState.NO_DATA)))
        val s = coolant.width / 480f
        var warm = 0
        for (y in 0 until (236 * s).toInt()) for (x in (300 * s).toInt() until coolant.width) {
            val c = coolant.getPixel(x, y)
            if (Color.red(c) - Color.blue(c) > 80) warm++
        }
        assertTrue("Expected the hatched coolant band, found $warm warm pixels", warm > 30)
        listOf(CarMetricIcon.SPEED, CarMetricIcon.RPM, CarMetricIcon.VOLTAGE).forEach { metric ->
            val bitmap = image(listOf(empty(metric, CarGaugeState.NO_DATA), empty(CarMetricIcon.RPM, CarGaugeState.NO_DATA)))
            for (y in 0 until bitmap.height) for (x in 0 until bitmap.width) {
                val c = bitmap.getPixel(x, y)
                assertTrue("$metric has a warm pixel at $x,$y", Color.red(c) - Color.blue(c) < 40)
            }
        }
    }

    @Test
    fun cacheReusesTheLatestImagesAndHoldsAtMostTwo() {
        val a = graphic.dashboard(pair(live(CarMetricIcon.SPEED, 1.0)), false)
        val b = graphic.dashboard(pair(live(CarMetricIcon.SPEED, 2.0)), false)
        assertSame(a, graphic.dashboard(pair(live(CarMetricIcon.SPEED, 1.0)), false))
        graphic.dashboard(pair(live(CarMetricIcon.SPEED, 3.0)), false)
        assertNotSame(b, graphic.dashboard(pair(live(CarMetricIcon.SPEED, 2.0)), false))
    }

    @Test
    fun emptyInputHasNoImage() {
        assertNull(graphic.dashboard(emptyList(), false))
        assertNotNull(graphic.dashboard(listOf(live(CarMetricIcon.SPEED, 10.0)), false))
    }

    @Test(expected = IllegalArgumentException::class)
    fun unsupportedMetricsDoNotInventAGaugeScale() {
        graphic.dashboard(listOf(live(CarMetricIcon.PRESSURE, 50.0)), false)
    }

    /**
     * Renders every readout state for review. Always asserts the states are distinct; writes PNG
     * files only when TELLTALE_GAUGE_DUMP_DIR is set.
     */
    @Test
    fun everyStateRendersDistinctImages_andCanBeExportedForReview() {
        val dumpDir = System.getenv("TELLTALE_GAUGE_DUMP_DIR")?.takeIf { it.isNotBlank() }?.let(::File)
        dumpDir?.mkdirs()
        val samples = mapOf(
            CarMetricIcon.SPEED to 88.0,
            CarMetricIcon.RPM to 3165.0,
            CarMetricIcon.TEMPERATURE to 108.0,
            CarMetricIcon.VOLTAGE to 14.1,
        )
        var rendered = 0
        val byCase = mutableMapOf<String, Bitmap>()
        listOf(false, true).forEach { dark ->
            val theme = if (dark) "night" else "day"
            samples.forEach { (metric, value) ->
                val name = metric.name.lowercase()
                val zero = if (metric == CarMetricIcon.TEMPERATURE) -40.0 else 0.0
                val cases = linkedMapOf(
                    "normal" to live(metric, value),
                    "zero" to live(metric, zero),
                    "warning" to live(metric, value, warning = true),
                    "missing" to empty(metric, CarGaugeState.NO_DATA),
                    "stale" to empty(metric, CarGaugeState.STALE),
                    "unsupported" to empty(metric, CarGaugeState.UNSUPPORTED),
                    "warning-stale" to empty(metric, CarGaugeState.STALE, warning = true),
                )
                val states = mutableListOf<Bitmap>()
                cases.forEach { (state, readout) ->
                    // The top readout is the case; the second slot shows a normal RPM for context.
                    val bitmap = image(pair(readout), dark)
                    states.forEach { assertFalse("$theme/$name/$state duplicates another state", it.sameAs(bitmap)) }
                    states += bitmap
                    byCase["$name/$state"]?.let { day ->
                        assertFalse("$name/$state is identical by day and night", day.sameAs(bitmap))
                    } ?: byCase.put("$name/$state", bitmap)
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

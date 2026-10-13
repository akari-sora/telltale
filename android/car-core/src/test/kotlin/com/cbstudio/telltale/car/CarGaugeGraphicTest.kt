package com.cbstudio.telltale.car

import android.graphics.Bitmap
import androidx.car.app.model.CarIcon
import androidx.car.app.model.GridItem
import androidx.car.app.testing.TestCarContext
import android.graphics.drawable.Icon
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
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

    private fun icon(
        value: Double?,
        metric: CarMetricIcon = CarMetricIcon.SPEED,
        warning: Boolean = false,
        dark: Boolean = true,
    ): CarIcon = graphic.icon(metric, value, warning, dark)

    private fun CarIcon.bitmap(): Bitmap {
        val compat = requireNotNull(icon)
        assertEquals(Icon.TYPE_BITMAP, compat.type)
        return requireNotNull(compat.bitmap)
    }

    @Test
    fun bitmap_hasFixedArgbSizeAndCanBeUsedAsLargeGridImage() {
        val carIcon = icon(120.0)
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
    fun missingAndNonFiniteValues_shareAnEmptyTrack() {
        val absent = icon(null)
        listOf(Double.NaN, Double.POSITIVE_INFINITY, Double.NEGATIVE_INFINITY).forEach {
            assertSame(absent, icon(it))
        }
        assertFalse(absent.bitmap().sameAs(icon(120.0).bitmap()))
    }

    @Test
    fun finiteZero_usesTheMetricVisualRange() {
        assertFalse(icon(null).bitmap().sameAs(icon(0.0).bitmap()))
        // Zero Celsius is above the temperature scale's -40 minimum, so it has a real value arc.
        assertFalse(
            icon(null, CarMetricIcon.TEMPERATURE).bitmap()
                .sameAs(icon(0.0, CarMetricIcon.TEMPERATURE).bitmap()),
        )
    }

    @Test
    fun outOfRangeValues_clampOnlyTheGraphicAtBothEnds() {
        val limits = listOf(
            Triple(CarMetricIcon.SPEED, 0.0, 240.0),
            Triple(CarMetricIcon.RPM, 0.0, 8_000.0),
            Triple(CarMetricIcon.TEMPERATURE, -40.0, 215.0),
            Triple(CarMetricIcon.VOLTAGE, 0.0, 24.0),
        )
        limits.forEach { (metric, min, max) ->
            assertSame(icon(min, metric), icon(min - 100.0, metric))
            assertSame(icon(max, metric), icon(max + 100.0, metric))
            assertFalse(icon(min, metric).bitmap().sameAs(icon(max, metric).bitmap()))
        }
    }

    @Test
    fun themeAndWarning_changePixelsAndWarningAddsRedundantMarker() {
        val normalDark = icon(120.0).bitmap()
        val normalLight = icon(120.0, dark = false).bitmap()
        val warningDark = icon(120.0, warning = true).bitmap()
        val warningLight = icon(120.0, warning = true, dark = false).bitmap()
        assertFalse(normalDark.sameAs(normalLight))
        assertFalse(normalDark.sameAs(warningDark))
        assertFalse(normalLight.sameAs(warningLight))
        // The badge sits in the arc's gap. This changes even when there is no finite value arc.
        val absent = icon(null).bitmap()
        val absentWarning = icon(null, warning = true).bitmap()
        assertFalse(absent.getPixel(58, 100) == absentWarning.getPixel(58, 100))
        assertEquals(absentWarning.getPixel(64, 86), absentWarning.getPixel(64, 98))
        assertFalse(absentWarning.getPixel(58, 100) == absentWarning.getPixel(64, 98))
    }

    @Test
    fun cache_reusesRecentImagesAndEvictsLeastRecentlyUsedAfterEightEntries() {
        val oldest = icon(1.0)
        val accessed = icon(2.0)
        (3..8).forEach { icon(it.toDouble()) }
        assertSame(accessed, icon(2.0))
        icon(9.0)
        assertSame(accessed, icon(2.0))
        assertNotSame(oldest, icon(1.0))
    }

    @Test(expected = IllegalArgumentException::class)
    fun unsupportedMetrics_doNotInventAGaugeScale() {
        icon(50.0, CarMetricIcon.PRESSURE)
    }
}

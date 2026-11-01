package com.cbstudio.telltale.car

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import androidx.annotation.ColorInt
import androidx.car.app.CarContext
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat
import com.cbstudio.telltale.car.health.CarAlertPolicy
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/** What a Grid gauge may claim about its signal. Only [LIVE] may draw a reading or value arc. */
internal enum class CarGaugeState {
    LIVE,
    STALE,
    NO_DATA,
    UNSUPPORTED,
}

/**
 * Supplementary instrument image for a GridItem (IMAGE_TYPE_LARGE).
 *
 * The bitmap repeats the tile's formatted reading as a large numeral so the value is the most
 * prominent element of the tile. The native GridItem text is still built from the same
 * [CarHomeScreen.MetricRow] and remains the authoritative, accessible reading, including the
 * localized `--`, `Stale` and `High` copy. Only a [CarGaugeState.LIVE] reading with a finite value
 * draws a number or a value arc; every other state draws `--`, never zero or a remembered value.
 *
 * Labelled ranges are visual scales, not warning thresholds. The only zone drawn is the coolant
 * alert region, read from [CarAlertPolicy.DEFAULT_COOLANT] so the image cannot invent a threshold.
 * Warning state comes from the alert repository and is shown by shape as well as colour.
 *
 * The image targets GridItem's 128 x 128 dp box at the car screen's density (CarContext resources
 * describe the car display), capped so that the bounded cache stays small.
 */
internal class CarGaugeGraphic(private val carContext: CarContext) {

    private data class Scale(
        val min: Double,
        val max: Double,
        val tickStep: Double,
        val unit: String,
        /** Start of the existing alert region, or null when the app has no alert for the metric. */
        val alertFrom: Double? = null,
    )

    private data class Key(
        val metric: CarMetricIcon,
        val state: CarGaugeState,
        val reading: String?,
        val sweep: Float?,
        val warning: Boolean,
        val dark: Boolean,
        val sizePx: Int,
    )

    private class Palette(
        @ColorInt val face: Int,
        @ColorInt val rim: Int,
        @ColorInt val track: Int,
        @ColorInt val majorTick: Int,
        @ColorInt val minorTick: Int,
        @ColorInt val primary: Int,
        @ColorInt val secondary: Int,
        @ColorInt val muted: Int,
        @ColorInt val accent: Int,
        @ColorInt val warning: Int,
    )

    private val cache = object : LinkedHashMap<Key, CarIcon>(CACHE_SIZE, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Key, CarIcon>?): Boolean =
            size > CACHE_SIZE
    }

    /**
     * @param reading the tile's formatted number without its unit, exactly as the native text shows it.
     */
    fun icon(
        metric: CarMetricIcon,
        value: Double?,
        reading: String?,
        state: CarGaugeState,
        warning: Boolean,
        dark: Boolean,
    ): CarIcon {
        val scale = scale(metric)
        val live = state == CarGaugeState.LIVE && value != null && value.isFinite() && !reading.isNullOrBlank()
        val sweep = if (live) {
            (((value!!.coerceIn(scale.min, scale.max) - scale.min) / (scale.max - scale.min)) * SWEEP).toFloat()
        } else null
        val key = Key(
            metric = metric,
            // A LIVE state without a finite reading is drawn exactly like missing data.
            state = if (state == CarGaugeState.LIVE && !live) CarGaugeState.NO_DATA else state,
            reading = if (live) reading else null,
            sweep = sweep,
            warning = warning,
            dark = dark,
            sizePx = sizePx(),
        )
        return cache.getOrPut(key) {
            CarIcon.Builder(IconCompat.createWithBitmap(draw(key, scale))).build()
        }
    }

    private fun sizePx(): Int {
        val density = carContext.resources.displayMetrics.density
        val scaled = if (density.isFinite() && density > 0f) (BOX_DP * density).roundToInt() else BOX_DP
        return scaled.coerceIn(BOX_DP, (BOX_DP * MAX_DENSITY).roundToInt())
    }

    private fun scale(metric: CarMetricIcon): Scale = when (metric) {
        CarMetricIcon.SPEED -> Scale(0.0, 240.0, 40.0, "km/h")
        CarMetricIcon.RPM -> Scale(0.0, 8_000.0, 1_000.0, "RPM")
        CarMetricIcon.TEMPERATURE -> Scale(
            -40.0, 215.0, 40.0, "°C",
            alertFrom = CarAlertPolicy.DEFAULT_COOLANT.enterThreshold,
        )
        CarMetricIcon.VOLTAGE -> Scale(0.0, 24.0, 4.0, "V")
        else -> throw IllegalArgumentException("No graphic scale for $metric")
    }

    // Hues follow the phone theme (lib/core/theme/app_colors.dart): aqua accent, red fault.
    private fun palette(dark: Boolean): Palette = if (dark) {
        // Night: lower luminance everywhere so the tiles do not glare in a dark cabin.
        Palette(
            face = rgb(0x0B, 0x0F, 0x14), rim = rgb(0x25, 0x2E, 0x3A),
            track = rgb(0x1F, 0x28, 0x33), majorTick = rgb(0x63, 0x6F, 0x7D), minorTick = rgb(0x3B, 0x45, 0x51),
            primary = rgb(0xDC, 0xE3, 0xEB), secondary = rgb(0x87, 0x96, 0xA8), muted = rgb(0x56, 0x61, 0x6E),
            accent = rgb(0x2B, 0xC2, 0xAD), warning = rgb(0xF0, 0x4A, 0x5A),
        )
    } else {
        // Day: still a dark instrument face (projected templates keep a dark background), with
        // brighter strokes and white numerals for contrast in sunlight.
        Palette(
            face = rgb(0x15, 0x1B, 0x23), rim = rgb(0x2E, 0x39, 0x47),
            track = rgb(0x2A, 0x35, 0x44), majorTick = rgb(0x9C, 0xA9, 0xB8), minorTick = rgb(0x5E, 0x6A, 0x78),
            primary = rgb(0xFF, 0xFF, 0xFF), secondary = rgb(0xB4, 0xC0, 0xCE), muted = rgb(0x7C, 0x87, 0x94),
            accent = rgb(0x35, 0xE0, 0xC8), warning = rgb(0xFF, 0x4D, 0x5E),
        )
    }

    private fun draw(key: Key, scale: Scale): Bitmap {
        val bitmap = Bitmap.createBitmap(key.sizePx, key.sizePx, Bitmap.Config.ARGB_8888)
        bitmap.density = carContext.resources.displayMetrics.densityDpi
        val canvas = Canvas(bitmap)
        // Draw in a fixed 128-unit space; scaling keeps every stroke and glyph crisp at host density.
        canvas.scale(key.sizePx / BOX_DP.toFloat(), key.sizePx / BOX_DP.toFloat())
        val p = palette(key.dark)
        val ink = if (key.warning) p.warning else p.accent
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }

        // Instrument face. Its own background keeps contrast independent of the host's template colour.
        fill.color = p.face
        canvas.drawCircle(C, C, FACE_R, fill)
        stroke.color = if (key.warning) p.warning else p.rim
        stroke.strokeWidth = if (key.warning) 3f else 1.5f
        canvas.drawCircle(C, C, FACE_R - stroke.strokeWidth / 2f, stroke)

        drawAlertZone(canvas, scale, p)

        // Track: solid normally, dotted when the reading is stale.
        val arc = RectF(C - ARC_R, C - ARC_R, C + ARC_R, C + ARC_R)
        val stale = key.state == CarGaugeState.STALE
        stroke.apply {
            strokeWidth = if (stale) STALE_W else ARC_W
            strokeCap = if (stale) Paint.Cap.BUTT else Paint.Cap.ROUND
            color = if (stale) p.minorTick else p.track
            pathEffect = if (stale) DashPathEffect(floatArrayOf(3.5f, 4.5f), 0f) else null
        }
        canvas.drawArc(arc, START, SWEEP, false, stroke)
        stroke.pathEffect = null
        stroke.strokeCap = Paint.Cap.ROUND
        stroke.strokeWidth = ARC_W

        drawTicks(canvas, scale, p)

        key.sweep?.let { sweep ->
            stroke.color = ink
            if (sweep > 0f) canvas.drawArc(arc, START, sweep, false, stroke)
            // Pointer: also marks a live minimum, so a real zero is never confused with missing data.
            val angle = Math.toRadians((START + sweep).toDouble())
            val x = C + ARC_R * cos(angle).toFloat()
            val y = C + ARC_R * sin(angle).toFloat()
            fill.color = ink
            canvas.drawCircle(x, y, 8f, fill)
            fill.color = p.face
            canvas.drawCircle(x, y, 3f, fill)
        }

        drawStatusGlyph(canvas, key, p)
        drawReading(canvas, key, scale, p)
        return bitmap
    }

    private fun drawAlertZone(canvas: Canvas, scale: Scale, p: Palette) {
        val from = scale.alertFrom ?: return
        val start = START + fraction(scale, from) * SWEEP
        val end = START + SWEEP
        // A hatched band: the region reads by pattern, not only by its warm colour.
        val band = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f
            color = p.warning
            alpha = 210
        }
        val r = ZONE_R
        canvas.drawArc(RectF(C - r, C - r, C + r, C + r), start, end - start, false, band)
        var a = start
        while (a <= end + 0.01f) {
            radial(canvas, a, r - 1f, r + 2f, band)
            a += 7f
        }
    }

    /** Evenly spaced scale ticks plus both ends; the host may show the image at about 64 dp. */
    private fun drawTicks(canvas: Canvas, scale: Scale, p: Palette) {
        val tick = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeWidth = 2.2f
            color = p.majorTick
        }
        var v = scale.min
        while (v < scale.max - 1e-9) {
            radial(canvas, START + fraction(scale, v) * SWEEP, TICK_IN, TICK_OUT, tick)
            v += scale.tickStep
        }
        radial(canvas, START + SWEEP, TICK_IN, TICK_OUT, tick)
    }

    private fun drawStatusGlyph(canvas: Canvas, key: Key, p: Palette) {
        val cx = C
        val cy = GLYPH_CY
        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2.6f
            strokeCap = Paint.Cap.ROUND
            color = p.secondary
        }
        when {
            key.warning -> {
                // Filled warning triangle with a cut-out exclamation mark: readable without colour.
                val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL; color = p.warning }
                val tri = Path().apply {
                    moveTo(cx, cy - 10.5f)
                    lineTo(cx + 12f, cy + 9.5f)
                    lineTo(cx - 12f, cy + 9.5f)
                    close()
                }
                canvas.drawPath(tri, fill)
                fill.color = p.face
                canvas.drawRoundRect(cx - 1.7f, cy - 4.5f, cx + 1.7f, cy + 3f, 1.4f, 1.4f, fill)
                canvas.drawCircle(cx, cy + 6f, 1.8f, fill)
            }
            key.state == CarGaugeState.STALE -> {
                // Clock: the last reading is too old to show.
                canvas.drawCircle(cx, cy, 9f, line)
                canvas.drawLine(cx, cy, cx, cy - 5.5f, line)
                canvas.drawLine(cx, cy, cx + 4f, cy + 2f, line)
            }
            key.state == CarGaugeState.UNSUPPORTED -> {
                // Prohibition sign: the vehicle does not report this signal.
                canvas.drawCircle(cx, cy, 9f, line)
                radial(canvas, cx, cy, 225f, -9f, 9f, line)
            }
            else -> {
                carContext.getDrawable(key.metric.drawableRes)?.mutate()?.apply {
                    setTint(if (key.state == CarGaugeState.LIVE) p.secondary else p.muted)
                    setBounds((cx - 10f).toInt(), (cy - 10f).toInt(), (cx + 10f).toInt(), (cy + 10f).toInt())
                    draw(canvas)
                }
            }
        }
    }

    private fun drawReading(canvas: Canvas, key: Key, scale: Scale, p: Palette) {
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            fontFeatureSettings = "tnum"
        }
        val reading = key.reading
        if (reading != null) {
            text.typeface = NUMERAL_TYPEFACE
            text.color = if (key.warning) p.warning else p.primary
            text.textSize = NUMERAL_SIZE
            val width = text.measureText(reading)
            if (width > NUMERAL_MAX_WIDTH) text.textSize = NUMERAL_SIZE * NUMERAL_MAX_WIDTH / width
            canvas.drawText(reading, C, NUMERAL_BASELINE, text)
            text.typeface = UNIT_TYPEFACE
            text.textSize = UNIT_SIZE
            text.color = p.secondary
            canvas.drawText(scale.unit, C, UNIT_BASELINE, text)
        } else {
            // Never a number: missing, unsupported and stale data all read as a placeholder.
            text.typeface = NUMERAL_TYPEFACE
            text.color = p.secondary
            text.textSize = NUMERAL_SIZE * 0.85f
            canvas.drawText(PLACEHOLDER, C, NUMERAL_BASELINE - 2f, text)
        }
    }

    private fun radial(canvas: Canvas, degrees: Float, from: Float, to: Float, paint: Paint) =
        radial(canvas, C, C, degrees, from, to, paint)

    private fun radial(canvas: Canvas, cx: Float, cy: Float, degrees: Float, from: Float, to: Float, paint: Paint) {
        val a = Math.toRadians(degrees.toDouble())
        val c = cos(a).toFloat()
        val s = sin(a).toFloat()
        canvas.drawLine(cx + from * c, cy + from * s, cx + to * c, cy + to * s, paint)
    }

    private fun fraction(scale: Scale, v: Double): Float =
        ((v.coerceIn(scale.min, scale.max) - scale.min) / (scale.max - scale.min)).toFloat()

    private companion object {
        const val BOX_DP = 128
        const val MAX_DENSITY = 2.5f
        const val CACHE_SIZE = 8
        const val START = 150f
        const val SWEEP = 240f
        const val C = 64f
        const val FACE_R = 63.5f
        const val ARC_R = 53f
        const val ARC_W = 10f
        const val STALE_W = 5f
        const val ZONE_R = 60.2f
        const val TICK_IN = 41f
        const val TICK_OUT = 46f
        const val GLYPH_CY = 30f
        const val NUMERAL_SIZE = 46f
        const val NUMERAL_MAX_WIDTH = 72f
        const val NUMERAL_BASELINE = 80f
        const val UNIT_SIZE = 17f
        const val UNIT_BASELINE = 104f
        const val PLACEHOLDER = "--"
        val NUMERAL_TYPEFACE: Typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
        val UNIT_TYPEFACE: Typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)

        fun rgb(r: Int, g: Int, b: Int): Int = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
    }
}

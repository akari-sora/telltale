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

/** What a gauge may claim about its signal. Only [LIVE] may draw a reading or value arc. */
internal enum class CarGaugeState {
    LIVE,
    STALE,
    NO_DATA,
    UNSUPPORTED,
}

/** One reading for the dashboard image, built from the same model row as its native Pane text. */
internal data class CarGaugeReadout(
    val metric: CarMetricIcon,
    val value: Double?,
    /** The formatted number without its unit, exactly as the native row text shows it. */
    val reading: String?,
    val state: CarGaugeState,
    val warning: Boolean,
)

/**
 * The single large image beside the Home Pane rows (Pane.Builder.setImage, Car API 4).
 *
 * The image exists for glanceability: Home passes Speed and RPM, each drawn as a large numeral
 * with its unit under a thin arc. Coolant and voltage stay as Pane rows, where a coolant warning
 * keeps its red row icon and `High` text. The native rows, built from the same model, remain the
 * authoritative and accessible readings, including the localized `--`, `Stale` and `High` text.
 * Only a [CarGaugeState.LIVE] reading with a finite value draws a number or value arc; every other
 * state draws `--` and, for stale or unsupported signals, a marker that reads without colour. Arc
 * ranges are unlabelled visual scales, not thresholds; the only zone the renderer can draw is the
 * coolant alert region from [CarAlertPolicy].
 *
 * The bitmap targets [BOX_DP] at the car screen's density (CarContext resources describe the car
 * display), capped at [MAX_DENSITY]. Android Auto 17.9 drew Pane images at 185–289 dp.
 */
internal class CarGaugeGraphic(private val carContext: CarContext) {

    private data class Scale(
        val min: Double,
        val max: Double,
        val unit: String,
        /** Start of the existing alert region, or null when the app has no alert for the metric. */
        val alertFrom: Double? = null,
    )

    private data class Key(
        val readouts: List<CarGaugeReadout>,
        val dark: Boolean,
        val sizePx: Int,
    )

    private class Palette(
        @ColorInt val panel: Int,
        @ColorInt val track: Int,
        @ColorInt val primary: Int,
        @ColorInt val secondary: Int,
        @ColorInt val accent: Int,
        @ColorInt val warning: Int,
    )

    private val cache = object : LinkedHashMap<Key, CarIcon>(CACHE_SIZE, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Key, CarIcon>?): Boolean =
            size > CACHE_SIZE
    }

    /**
     * Returns the dashboard image for the first [READOUTS] readouts, stacked as wide panels, or null
     * when it cannot be drawn (the Pane then shows its rows only). A 2 × 2 layout was measured on the
     * DHU and rejected: four-digit RPM reached only 24 dp cap height at 1280 × 720 (AA-11).
     */
    fun dashboard(readouts: List<CarGaugeReadout>, dark: Boolean): CarIcon? {
        val shown = readouts.take(READOUTS).map(::normalized)
        if (shown.isEmpty()) return null
        val key = Key(shown, dark, sizePx())
        cache[key]?.let { return it }
        return try {
            CarIcon.Builder(IconCompat.createWithBitmap(draw(key))).build().also { cache[key] = it }
        } catch (_: Exception) {
            null
        } catch (_: OutOfMemoryError) {
            null
        }
    }

    /** A LIVE state without a finite value and reading is drawn exactly like missing data. */
    private fun normalized(r: CarGaugeReadout): CarGaugeReadout {
        scale(r.metric) // Unsupported metrics fail before anything is drawn.
        val live = r.state == CarGaugeState.LIVE && r.value != null && r.value.isFinite() && !r.reading.isNullOrBlank()
        return if (live) {
            r
        } else {
            r.copy(
                value = null,
                reading = null,
                state = if (r.state == CarGaugeState.LIVE) CarGaugeState.NO_DATA else r.state,
            )
        }
    }

    private fun sizePx(): Int {
        val density = carContext.resources.displayMetrics.density
        val scaled = if (density.isFinite() && density > 0f) (BOX_DP * density).roundToInt() else BOX_DP
        return scaled.coerceIn(BOX_DP, (BOX_DP * MAX_DENSITY).roundToInt())
    }

    private fun scale(metric: CarMetricIcon): Scale = when (metric) {
        CarMetricIcon.SPEED -> Scale(0.0, 240.0, "km/h")
        CarMetricIcon.RPM -> Scale(0.0, 8_000.0, "RPM")
        CarMetricIcon.TEMPERATURE -> Scale(
            -40.0, 215.0, "°C",
            alertFrom = CarAlertPolicy.DEFAULT_COOLANT.enterThreshold,
        )
        CarMetricIcon.VOLTAGE -> Scale(0.0, 24.0, "V")
        else -> throw IllegalArgumentException("No graphic scale for $metric")
    }

    // Hues follow the phone theme (lib/core/theme/app_colors.dart): aqua accent, red fault.
    private fun palette(dark: Boolean): Palette = if (dark) {
        // Night: lower luminance so the image does not glare in a dark cabin.
        Palette(
            panel = rgb(0x0B, 0x0F, 0x14), track = rgb(0x2A, 0x33, 0x3F),
            primary = rgb(0xDC, 0xE3, 0xEB), secondary = rgb(0x8C, 0x9A, 0xAB),
            accent = rgb(0x2B, 0xC2, 0xAD), warning = rgb(0xF0, 0x4A, 0x5A),
        )
    } else {
        // Day: projected templates keep a dark background, so keep a dark panel with white numerals.
        Palette(
            panel = rgb(0x15, 0x1B, 0x23), track = rgb(0x34, 0x40, 0x4E),
            primary = rgb(0xFF, 0xFF, 0xFF), secondary = rgb(0xB4, 0xC0, 0xCE),
            accent = rgb(0x35, 0xE0, 0xC8), warning = rgb(0xFF, 0x4D, 0x5E),
        )
    }

    private fun draw(key: Key): Bitmap {
        val bitmap = Bitmap.createBitmap(key.sizePx, key.sizePx, Bitmap.Config.ARGB_8888)
        bitmap.density = carContext.resources.displayMetrics.densityDpi
        val canvas = Canvas(bitmap)
        // Draw in a fixed 480-unit space; scaling keeps strokes and numerals crisp at host density.
        canvas.scale(key.sizePx / UNITS, key.sizePx / UNITS)
        val p = palette(key.dark)
        key.readouts.forEachIndexed { i, r ->
            drawWide(canvas, RectF(0f, i * 244f, UNITS, i * 244f + 236f), r, p)
        }
        return bitmap
    }

    /**
     * A wide readout: thin half-circle arc, the unit (or a state marker) at the top inside it, and
     * the numeral using the full width underneath.
     */
    private fun drawWide(canvas: Canvas, cell: RectF, r: CarGaugeReadout, p: Palette) {
        val scale = scale(r.metric)
        drawPanel(canvas, cell, r, p)
        val cx = cell.centerX()
        val cy = cell.top + 214f
        drawArc(canvas, cx, cy, 196f, 180f, 180f, 9f, r, scale, p)
        val unitPaint = unitPaint(44f, p)
        val unit = if (r.reading != null) scale.unit else null
        val markerSize = if (hasMarker(r)) 22f else 0f
        val unitWidth = unit?.let(unitPaint::measureText) ?: 0f
        val gap = if (markerSize > 0f && unit != null) 18f else 0f
        var x = cx - (markerSize * 2.3f + gap + unitWidth) / 2f
        if (markerSize > 0f) {
            drawMarker(canvas, x + markerSize * 1.15f, cell.top + 74f, markerSize, r, p)
            x += markerSize * 2.3f + gap
        }
        unit?.let { canvas.drawText(it, x, cell.top + 90f, unitPaint) }
        drawNumeral(canvas, cx, cell.top + 210f, maxWidth = 344f, size = 140f, r, p)
    }

    private fun hasMarker(r: CarGaugeReadout): Boolean =
        r.warning || r.state == CarGaugeState.STALE || r.state == CarGaugeState.UNSUPPORTED

    private fun unitPaint(size: Float, p: Palette) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = UNIT_TYPEFACE
        textSize = size
        color = p.secondary
        textAlign = Paint.Align.LEFT
    }

    private fun drawPanel(canvas: Canvas, cell: RectF, r: CarGaugeReadout, p: Palette) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL; color = p.panel }
        canvas.drawRoundRect(cell, 28f, 28f, paint)
        if (r.warning) {
            // Thick warning frame: a shape cue in addition to colour.
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 8f
            paint.color = p.warning
            canvas.drawRoundRect(RectF(cell.left + 4f, cell.top + 4f, cell.right - 4f, cell.bottom - 4f), 24f, 24f, paint)
        }
    }

    private fun drawArc(
        canvas: Canvas,
        cx: Float,
        cy: Float,
        radius: Float,
        start: Float,
        sweep: Float,
        width: Float,
        r: CarGaugeReadout,
        scale: Scale,
        p: Palette,
    ) {
        val oval = RectF(cx - radius, cy - radius, cx + radius, cy + radius)
        val stale = r.state == CarGaugeState.STALE
        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = width
            strokeCap = if (stale) Paint.Cap.BUTT else Paint.Cap.ROUND
            color = p.track
            // Dotted track for stale data: a pattern, not only a colour.
            pathEffect = if (stale) DashPathEffect(floatArrayOf(6f, 9f), 0f) else null
        }
        canvas.drawArc(oval, start, sweep, false, stroke)
        stroke.pathEffect = null
        stroke.strokeCap = Paint.Cap.ROUND

        scale.alertFrom?.let { from ->
            // Hatched band outside the arc for the existing coolant alert region only.
            val a0 = start + fraction(scale, from) * sweep
            val band = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 3f
                color = p.warning
            }
            val rb = radius + width / 2f + 7f
            canvas.drawArc(RectF(cx - rb, cy - rb, cx + rb, cy + rb), a0, start + sweep - a0, false, band)
            var a = a0
            while (a <= start + sweep + 0.01f) {
                radial(canvas, cx, cy, a, rb, rb + 7f, band)
                a += 8f
            }
        }

        if (r.state != CarGaugeState.LIVE || r.value == null) return
        val ink = if (r.warning) p.warning else p.accent
        val valueSweep = fraction(scale, r.value) * sweep
        stroke.color = ink
        if (valueSweep > 0f) canvas.drawArc(oval, start, valueSweep, false, stroke)
        // Pointer: also marks a live minimum, so a real zero never looks like missing data.
        val angle = Math.toRadians((start + valueSweep).toDouble())
        val dot = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL; color = ink }
        canvas.drawCircle(cx + radius * cos(angle).toFloat(), cy + radius * sin(angle).toFloat(), width * 1.4f, dot)
    }

    private fun drawMarker(canvas: Canvas, cx: Float, cy: Float, size: Float, r: CarGaugeReadout, p: Palette) {
        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = size * 0.22f
            strokeCap = Paint.Cap.ROUND
            color = p.secondary
        }
        when {
            r.warning -> {
                // Filled triangle with a cut-out exclamation mark: readable without colour.
                val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL; color = p.warning }
                canvas.drawPath(
                    Path().apply {
                        moveTo(cx, cy - size)
                        lineTo(cx + size * 1.15f, cy + size * 0.95f)
                        lineTo(cx - size * 1.15f, cy + size * 0.95f)
                        close()
                    },
                    fill,
                )
                fill.color = p.panel
                canvas.drawRoundRect(cx - size * 0.15f, cy - size * 0.45f, cx + size * 0.15f, cy + size * 0.3f, 2f, 2f, fill)
                canvas.drawCircle(cx, cy + size * 0.6f, size * 0.17f, fill)
            }
            r.state == CarGaugeState.STALE -> {
                // Clock: the last reading is too old to show.
                canvas.drawCircle(cx, cy, size, line)
                canvas.drawLine(cx, cy, cx, cy - size * 0.6f, line)
                canvas.drawLine(cx, cy, cx + size * 0.45f, cy + size * 0.25f, line)
            }
            r.state == CarGaugeState.UNSUPPORTED -> {
                // Prohibition sign: the vehicle does not report this signal.
                canvas.drawCircle(cx, cy, size, line)
                radial(canvas, cx, cy, 225f, -size, size, line)
            }
        }
    }

    private fun drawNumeral(
        canvas: Canvas,
        cx: Float,
        baseline: Float,
        maxWidth: Float,
        size: Float,
        r: CarGaugeReadout,
        p: Palette,
    ) {
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = NUMERAL_TYPEFACE
            fontFeatureSettings = "tnum"
            textAlign = Paint.Align.LEFT
        }
        val reading = r.reading
        if (reading == null) {
            // Never a number: missing, unsupported and stale data all read as a placeholder.
            text.textSize = size * 0.8f
            text.color = p.secondary
            val w = text.measureText(PLACEHOLDER)
            canvas.drawText(PLACEHOLDER, cx - w / 2f, baseline - size * 0.08f, text)
            return
        }
        text.color = if (r.warning) p.warning else p.primary
        text.textSize = size
        val numeralWidth = text.measureText(reading)
        if (numeralWidth > maxWidth) text.textSize = size * maxWidth / numeralWidth
        canvas.drawText(reading, cx - text.measureText(reading) / 2f, baseline, text)
    }

    private fun radial(canvas: Canvas, cx: Float, cy: Float, degrees: Float, from: Float, to: Float, paint: Paint) {
        val a = Math.toRadians(degrees.toDouble())
        val c = cos(a).toFloat()
        val s = sin(a).toFloat()
        canvas.drawLine(cx + from * c, cy + from * s, cx + to * c, cy + to * s, paint)
    }

    private fun fraction(scale: Scale, v: Double): Float =
        ((v.coerceIn(scale.min, scale.max) - scale.min) / (scale.max - scale.min)).toFloat()

    private companion object {
        const val BOX_DP = 320
        const val MAX_DENSITY = 2f
        const val CACHE_SIZE = 2
        const val READOUTS = 2
        const val UNITS = 480f
        const val PLACEHOLDER = "--"
        val NUMERAL_TYPEFACE: Typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
        val UNIT_TYPEFACE: Typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)

        fun rgb(r: Int, g: Int, b: Int): Int = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
    }
}

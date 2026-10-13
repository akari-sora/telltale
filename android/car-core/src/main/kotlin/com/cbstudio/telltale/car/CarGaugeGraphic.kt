package com.cbstudio.telltale.car

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import androidx.car.app.CarContext
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat
import kotlin.math.cos
import kotlin.math.sin

/**
 * A supplementary image for a GridItem using IMAGE_TYPE_LARGE. The host controls its displayed size.
 * Exact values, units and availability belong in the native GridItem text, never in this bitmap.
 * The labelled ranges are visual scales, not warning thresholds or vehicle health limits.
 */
internal class CarGaugeGraphic(private val carContext: CarContext) {

    private data class Scale(val min: Double, val max: Double, val minLabel: String, val maxLabel: String)

    private data class Key(
        val metric: CarMetricIcon,
        val sweep: Float?,
        val warning: Boolean,
        val dark: Boolean,
    )

    private val cache = object : LinkedHashMap<Key, CarIcon>(CACHE_SIZE, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Key, CarIcon>?): Boolean =
            size > CACHE_SIZE
    }

    fun icon(metric: CarMetricIcon, value: Double?, warning: Boolean, dark: Boolean): CarIcon {
        val scale = scale(metric)
        val sweep = value?.takeIf { it.isFinite() }?.let {
            (((it.coerceIn(scale.min, scale.max) - scale.min) / (scale.max - scale.min)) * SWEEP)
                .toFloat()
        }
        val key = Key(metric, sweep, warning, dark)
        return cache.getOrPut(key) {
            CarIcon.Builder(IconCompat.createWithBitmap(draw(key, scale))).build()
        }
    }

    private fun scale(metric: CarMetricIcon): Scale = when (metric) {
        CarMetricIcon.SPEED -> Scale(0.0, 240.0, "0", "240")
        CarMetricIcon.RPM -> Scale(0.0, 8_000.0, "0", "8000")
        CarMetricIcon.TEMPERATURE -> Scale(-40.0, 215.0, "-40", "215")
        CarMetricIcon.VOLTAGE -> Scale(0.0, 24.0, "0", "24")
        else -> throw IllegalArgumentException("No graphic scale for $metric")
    }

    private fun draw(key: Key, scale: Scale): Bitmap {
        val bitmap = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = if (key.dark) Color.rgb(16, 24, 32) else Color.rgb(250, 250, 250)
        val foreground = if (key.dark) Color.WHITE else Color.rgb(24, 34, 45)
        val track = if (key.dark) Color.rgb(113, 128, 150) else Color.rgb(115, 125, 135)
        val accent = when {
            key.warning && key.dark -> Color.rgb(255, 133, 133)
            key.warning -> Color.rgb(176, 0, 32)
            key.dark -> Color.rgb(81, 222, 255)
            else -> Color.rgb(0, 94, 168)
        }
        // Keep the instrument's background circular while retaining contrast
        // when a host uses a different palette from CarContext's day/night mode.
        canvas.drawCircle(64f, 64f, 64f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = background })
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 9f
            strokeCap = Paint.Cap.BUTT
            color = track
        }
        val arcBounds = RectF(14f, 14f, 114f, 114f)
        canvas.drawArc(arcBounds, START, SWEEP, false, paint)
        key.sweep?.let {
            paint.color = accent
            if (it > 0f) canvas.drawArc(arcBounds, START, it, false, paint)
            // A finite minimum has a marker; missing/non-finite values leave only the empty track.
            val angle = Math.toRadians((START + it).toDouble())
            paint.style = Paint.Style.FILL
            canvas.drawCircle(
                64f + 50f * cos(angle).toFloat(),
                64f + 50f * sin(angle).toFloat(),
                4.5f,
                paint,
            )
        }

        carContext.getDrawable(key.metric.drawableRes)?.mutate()?.apply {
            setTint(if (key.warning) accent else foreground)
            setBounds(44, 42, 84, 82)
            draw(canvas)
        }

        paint.apply {
            style = Paint.Style.FILL
            color = foreground
            textAlign = Paint.Align.CENTER
            textSize = 14f
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        }
        canvas.drawText(scale.minLabel, 34f, 106f, paint)
        canvas.drawText(scale.maxLabel, 94f, 106f, paint)

        // Redundant shape: a warning remains distinguishable without relying on its red colour.
        if (key.warning) {
            paint.color = accent
            canvas.drawCircle(64f, 100f, 10f, paint)
            paint.color = background
            canvas.drawRoundRect(62.5f, 93f, 65.5f, 101f, 1f, 1f, paint)
            canvas.drawCircle(64f, 105f, 1.7f, paint)
        }
        return bitmap
    }

    private companion object {
        const val SIZE = 128
        const val CACHE_SIZE = 8
        const val START = 150f
        const val SWEEP = 240f
    }
}

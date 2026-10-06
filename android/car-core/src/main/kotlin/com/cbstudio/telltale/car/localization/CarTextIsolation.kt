package com.cbstudio.telltale.car.localization

import android.content.Context
import android.view.View
import java.util.Locale

/**
 * Text isolation utilities for Android for Cars UI.
 *
 * Ensures technical tokens such as OBD-II Diagnostic Trouble Codes (e.g. "P0300")
 * and formatted telemetry metrics (e.g. "13.8 V", "800 RPM", "98 °C") preserve
 * strict Left-to-Right (LTR) character order when rendered in Right-to-Left (RTL)
 * locales (such as Arabic or Hebrew) or mixed bidirectional (BiDi) display contexts.
 */
object CarTextIsolation {

    /** Unicode Left-to-Right Isolate (U+2066). */
    const val LEFT_TO_RIGHT_ISOLATE = '\u2066'

    /** Unicode Pop Directional Isolate (U+2069). */
    const val POP_DIRECTIONAL_ISOLATE = '\u2069'

    /** Unicode Left-to-Right Mark (U+200E). */
    const val LEFT_TO_RIGHT_MARK = '\u200E'

    /**
     * Determines whether the given context or system environment is in an RTL layout direction.
     */
    fun isRtlContext(context: Context?): Boolean {
        if (context != null) {
            val config = context.resources.configuration
            return config.layoutDirection == View.LAYOUT_DIRECTION_RTL
        }
        val defaultLocale = Locale.getDefault()
        return try {
            android.text.TextUtils.getLayoutDirectionFromLocale(defaultLocale) == View.LAYOUT_DIRECTION_RTL
        } catch (_: Throwable) {
            val name = defaultLocale.displayName
            if (name.isNotEmpty()) {
                val dir = Character.getDirectionality(name[0])
                dir == Character.DIRECTIONALITY_RIGHT_TO_LEFT || dir == Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC
            } else {
                false
            }
        }
    }

    /**
     * Wraps the provided text in Unicode LTR isolate delimiters (U+2066 ... U+2069).
     *
     * In bidirectional text processing, an isolate treats its content as an independent
     * paragraph with LTR directionality, preventing surrounding RTL characters from
     * transposing numbers, punctuation, or units.
     */
    fun isolateLtr(text: CharSequence): String {
        return "$LEFT_TO_RIGHT_ISOLATE$text$POP_DIRECTIONAL_ISOLATE"
    }

    /**
     * Wraps a diagnostic trouble code (e.g. "P0300") with LTR isolation if [isRtl] is true.
     * When [isRtl] is false, returns the clean raw code for standard LTR rendering.
     */
    fun wrapDtcCode(code: String, isRtl: Boolean = true): String {
        return if (isRtl) isolateLtr(code) else code
    }

    /**
     * Wraps a diagnostic trouble code (e.g. "P0300") with LTR isolation based on the context layout direction.
     */
    fun wrapDtcCode(code: String, context: Context?): String {
        return wrapDtcCode(code, isRtlContext(context))
    }

    /**
     * Formats and wraps a metric value with its unit (e.g. "13.8 V", "98 °C") with LTR isolation if [isRtl] is true.
     * When [isRtl] is false, returns the standard "$value $unit" string for LTR rendering.
     */
    fun wrapMetric(value: Any, unit: String, isRtl: Boolean = true): String {
        val raw = if (unit.isBlank()) "$value" else "$value $unit"
        return if (isRtl) isolateLtr(raw) else raw
    }

    /**
     * Formats and wraps a metric value with its unit based on context layout direction.
     */
    fun wrapMetric(value: Any, unit: String, context: Context?): String {
        return wrapMetric(value, unit, isRtlContext(context))
    }

    /**
     * Checks if the given text is enclosed within LTR isolate control characters.
     */
    fun isLtrIsolated(text: CharSequence): Boolean {
        if (text.length < 2) return false
        return text.first() == LEFT_TO_RIGHT_ISOLATE && text.last() == POP_DIRECTIONAL_ISOLATE
    }

    /**
     * Strips bidirectional isolate markers from a string, returning the raw text.
     */
    fun stripIsolation(text: String): String {
        return text
            .replace(LEFT_TO_RIGHT_ISOLATE.toString(), "")
            .replace(POP_DIRECTIONAL_ISOLATE.toString(), "")
            .replace(LEFT_TO_RIGHT_MARK.toString(), "")
    }
}

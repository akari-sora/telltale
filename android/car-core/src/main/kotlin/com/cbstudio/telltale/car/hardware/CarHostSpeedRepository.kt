package com.cbstudio.telltale.car.hardware

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Repository holding the latest [CarHostSpeedSample] from host CarInfo (AA-05).
 *
 * Provides thread-safe StateFlow access and staleness evaluation against [maxAgeMs].
 */
class CarHostSpeedRepository(
    val maxAgeMs: Long = DEFAULT_MAX_AGE_MS,
) {
    companion object {
        const val DEFAULT_MAX_AGE_MS = 3_000L
    }

    private val _sample = MutableStateFlow(CarHostSpeedSample.INITIAL)
    val sample: StateFlow<CarHostSpeedSample> = _sample.asStateFlow()

    fun updateSample(newSample: CarHostSpeedSample) {
        _sample.value = newSample
    }

    fun checkFreshness(elapsedRealtimeMs: Long) {
        val current = _sample.value
        if (current.status == CarHostSpeedStatus.LIVE) {
            val received = current.receivedAtElapsedMs ?: 0L
            if (elapsedRealtimeMs - received > maxAgeMs) {
                _sample.value = current.copy(
                    status = CarHostSpeedStatus.STALE,
                    rawMetersPerSecond = null,
                    displaySpeedMetersPerSecond = null,
                )
            }
        }
    }

    fun reset() {
        _sample.value = CarHostSpeedSample.INITIAL
    }
}

package com.cbstudio.telltale.car.hardware

import android.os.SystemClock
import androidx.car.app.CarContext
import androidx.car.app.hardware.CarHardwareManager
import androidx.car.app.hardware.common.CarValue
import androidx.car.app.hardware.common.OnCarDataAvailableListener
import androidx.car.app.hardware.info.CarInfo
import androidx.car.app.hardware.info.Speed
import androidx.car.app.versioning.CarAppApiLevels
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor

/**
 * Production implementation of [CarHardwareSpeedGateway] using [CarHardwareManager.getCarInfo] (AA-05).
 *
 * Adheres to:
 * - AA05-02: Speed is obtained via [CarInfo.addSpeedListener], NEVER CarSensors.
 * - AA05-03: Car App API < 3 fail-closed to [CarHostSpeedStatus.UNIMPLEMENTED].
 * - AA05-07 & AA05-08: Only STATUS_SUCCESS with finite float is LIVE, never fabricates 0.
 */
class AndroidCarHardwareSpeedGateway(
    private val carContext: CarContext,
    private val clock: () -> Long = SystemClock::elapsedRealtime,
    private val executor: Executor? = null,
) : CarHardwareSpeedGateway {

    private var speedListener: OnCarDataAvailableListener<Speed>? = null
    private var carInfoRef: CarInfo? = null
    private var activeRegistrationToken: Long = 0L

    override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
        stopListening()
        val regToken = ++activeRegistrationToken

        // AA05-03: Car App API < 3 fail closed to UNIMPLEMENTED
        val apiLevel = try {
            carContext.carAppApiLevel
        } catch (_: Throwable) {
            CarAppApiLevels.LEVEL_1
        }

        if (apiLevel < CarAppApiLevels.LEVEL_3) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.UNIMPLEMENTED,
                    receivedAtElapsedMs = clock(),
                )
            )
            return
        }

        val hardwareManager = try {
            carContext.getCarService(CarHardwareManager::class.java)
        } catch (_: SecurityException) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.PERMISSION_DENIED,
                    receivedAtElapsedMs = clock(),
                )
            )
            return
        } catch (_: Throwable) {
            null
        }

        val carInfo = try {
            hardwareManager?.carInfo
        } catch (_: SecurityException) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.PERMISSION_DENIED,
                    receivedAtElapsedMs = clock(),
                )
            )
            return
        } catch (_: Throwable) {
            null
        }

        if (carInfo == null) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.UNIMPLEMENTED,
                    receivedAtElapsedMs = clock(),
                )
            )
            return
        }
        carInfoRef = carInfo

        val listener = OnCarDataAvailableListener<Speed> { speed ->
            if (speedListener == null || regToken != activeRegistrationToken) return@OnCarDataAvailableListener
            val now = clock()
            val sample = parseSpeed(speed, now)
            onSpeedAvailable(sample)
        }
        speedListener = listener

        val exec = executor ?: try {
            ContextCompat.getMainExecutor(carContext)
        } catch (_: Throwable) {
            Executor { it.run() }
        }

        try {
            carInfo.addSpeedListener(exec, listener)
        } catch (_: SecurityException) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.PERMISSION_DENIED,
                    receivedAtElapsedMs = clock(),
                )
            )
        } catch (_: UnsupportedOperationException) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.UNIMPLEMENTED,
                    receivedAtElapsedMs = clock(),
                )
            )
        } catch (_: Throwable) {
            onSpeedAvailable(
                CarHostSpeedSample(
                    status = CarHostSpeedStatus.UNAVAILABLE,
                    receivedAtElapsedMs = clock(),
                )
            )
        }
    }

    override fun stopListening() {
        val listener = speedListener
        val carInfo = carInfoRef
        speedListener = null
        carInfoRef = null
        activeRegistrationToken++
        if (listener != null && carInfo != null) {
            try {
                carInfo.removeSpeedListener(listener)
            } catch (_: Throwable) {
                // Ignore failure during unregister
            }
        }
    }

    internal fun parseSpeed(speed: Speed, nowElapsedMs: Long): CarHostSpeedSample {
        val rawVal = speed.rawSpeedMetersPerSecond
        val dispVal = speed.displaySpeedMetersPerSecond

        val rawStatus = rawVal.status
        val dispStatus = dispVal.status

        // AA05-07 & AA05-08: Only STATUS_SUCCESS with finite float is LIVE
        val rawLive = rawStatus == CarValue.STATUS_SUCCESS && rawVal.value != null && rawVal.value!!.isFinite()
        val dispLive = dispStatus == CarValue.STATUS_SUCCESS && dispVal.value != null && dispVal.value!!.isFinite()

        val status = when {
            rawLive || dispLive -> CarHostSpeedStatus.LIVE
            rawStatus == CarValue.STATUS_UNIMPLEMENTED || dispStatus == CarValue.STATUS_UNIMPLEMENTED -> CarHostSpeedStatus.UNIMPLEMENTED
            else -> CarHostSpeedStatus.UNAVAILABLE
        }

        return CarHostSpeedSample(
            status = status,
            rawMetersPerSecond = if (rawLive) rawVal.value else null,
            displaySpeedMetersPerSecond = if (dispLive) dispVal.value else null,
            sourceTimestampElapsedMs = dispVal.timestampMillis.takeIf { it > 0 } ?: rawVal.timestampMillis.takeIf { it > 0 },
            receivedAtElapsedMs = nowElapsedMs,
        )
    }
}

package com.cbstudio.telltale.car

import android.os.SystemClock
import androidx.car.app.CarContext
import com.cbstudio.telltale.car.diagnostics.CarDtcRepository
import com.cbstudio.telltale.car.diagnostics.CarDtcRuntime
import com.cbstudio.telltale.car.hardware.AndroidCarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedPermissionCoordinator
import com.cbstudio.telltale.car.hardware.CarHostSpeedRepository
import com.cbstudio.telltale.car.hardware.CarSpeedResolver
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
import com.cbstudio.telltale.car.health.CarAlertCoordinator
import com.cbstudio.telltale.car.health.CarAlertRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryRuntime
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Session-scoped runtime wiring host hardware speed gateway, alert coordinator, and permission coordinator (AA05-21, AA05-22).
 */
class CarSessionRuntime(
    val carContext: CarContext,
    val telemetryRepository: CarTelemetryRepository = CarTelemetryRuntime.repository,
    val dtcRepository: CarDtcRepository = CarDtcRuntime.repository,
    val hostSpeedGateway: CarHardwareSpeedGateway = AndroidCarHardwareSpeedGateway(carContext),
    val hostSpeedRepository: CarHostSpeedRepository = CarHostSpeedRepository(),
    val speedResolver: CarSpeedResolver = CarSpeedResolver(),
    val motionResolver: CarVehicleMotionResolver = CarVehicleMotionResolver(),
    val alertCoordinator: CarAlertCoordinator = CarAlertCoordinator(telemetryRepository),
    val alertRepository: CarAlertRepository = alertCoordinator.repository,
    private val clock: () -> Long = SystemClock::elapsedRealtime,
    private val coroutineScope: CoroutineScope? = null,
) {
    val permissionCoordinator: CarHostSpeedPermissionCoordinator = CarHostSpeedPermissionCoordinator {
        retryHostSpeed()
    }

    private var internalScope: CoroutineScope? = null
    private var freshnessJob: Job? = null
    private var currentRegistrationToken: Long = 0L
    var isStarted = false
        private set

    fun start() {
        if (isStarted) return
        isStarted = true
        val registrationToken = ++currentRegistrationToken

        hostSpeedRepository.reset()
        hostSpeedGateway.startListening { sample ->
            if (!isStarted || registrationToken != currentRegistrationToken) return@startListening
            hostSpeedRepository.updateSample(sample)
        }

        alertCoordinator.start()

        // R4: Seamless snapshot replay if producer and connection epoch have not changed
        val currentTelemetryEpoch = when (val tState = telemetryRepository.state.value) {
            is CarTelemetryState.Current -> tState.frame.connectionEpoch
            is CarTelemetryState.Stale -> tState.connectionEpoch
            else -> null
        }
        dtcRepository.replaySnapshot(expectedEpoch = currentTelemetryEpoch)

        val scope = getScope()
        freshnessJob = scope.launch {
            while (true) {
                delay(1_000L)
                hostSpeedRepository.checkFreshness(clock())
            }
        }
    }

    fun retryHostSpeed() {
        if (!isStarted) return
        val registrationToken = ++currentRegistrationToken
        hostSpeedGateway.stopListening()
        hostSpeedRepository.reset()
        hostSpeedGateway.startListening { sample ->
            if (!isStarted || registrationToken != currentRegistrationToken) return@startListening
            hostSpeedRepository.updateSample(sample)
        }
    }

    fun stop() {
        if (!isStarted) return
        isStarted = false
        ++currentRegistrationToken

        freshnessJob?.cancel()
        freshnessJob = null

        hostSpeedGateway.stopListening()
        hostSpeedRepository.reset()
        alertCoordinator.stop()
        dtcRepository.reset(clearSnapshot = false)
    }

    fun destroy() {
        stop()
        ++currentRegistrationToken
        internalScope?.cancel()
        internalScope = null

        alertCoordinator.destroy()
        hostSpeedRepository.reset()
        dtcRepository.reset(clearSnapshot = true)
    }

    private fun getScope(): CoroutineScope {
        return coroutineScope ?: internalScope ?: run {
            val dispatcher = try {
                Dispatchers.Main.immediate
            } catch (_: Throwable) {
                Dispatchers.Default
            }
            CoroutineScope(SupervisorJob() + dispatcher).also {
                internalScope = it
            }
        }
    }
}

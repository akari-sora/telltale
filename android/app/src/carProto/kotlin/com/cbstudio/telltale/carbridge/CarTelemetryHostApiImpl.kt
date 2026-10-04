package com.cbstudio.telltale.carbridge

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.carbridge.generated.CarConnectionPhaseMessage
import com.cbstudio.telltale.carbridge.generated.CarSignalDoubleMessage
import com.cbstudio.telltale.carbridge.generated.CarSignalStatusMessage
import com.cbstudio.telltale.carbridge.generated.CarTelemetryHostApi
import com.cbstudio.telltale.carbridge.generated.CarTelemetryMessage

/**
 * The carProto-only receiving end of the one-way telemetry bridge.
 *
 * It decodes the Pigeon message into car-core's transport-neutral input and
 * hands it to the repository, which owns all validation. It never answers the
 * producer with data and never calls into Dart.
 *
 * Constructing it counts as a producer (re)attach: a new FlutterEngine starts
 * its sequence numbers again, and the repository must not reject them forever
 * because an earlier engine counted higher.
 */
class CarTelemetryHostApiImpl(
    private val repository: CarTelemetryRepository,
) : CarTelemetryHostApi {

    init {
        repository.onProducerAttached()
    }

    override fun publishTelemetryFrame(frame: CarTelemetryMessage) {
        repository.submit(frame.toFrameInput())
    }
}

internal fun CarTelemetryMessage.toFrameInput(): CarTelemetryFrameInput =
    CarTelemetryFrameInput(
        schemaVersion = schemaVersion,
        sequence = sequence,
        connectionEpoch = connectionEpoch,
        lifecycleEpoch = lifecycleEpoch,
        producedAtMonotonicUs = producedAtMonotonicUs,
        connectionPhase = connectionPhase.toCar(),
        speedKmh = speedKmh.toCar(),
        rpm = rpm.toCar(),
        coolantC = coolantC.toCar(),
        intakeAirC = intakeAirC.toCar(),
        controlModuleVoltageV = controlModuleVoltageV.toCar(),
        mapKpa = mapKpa.toCar(),
        diagnosticsAvailable = diagnosticsAvailable,
        milOn = milOn,
        dtcCount = dtcCount,
    )

private fun CarConnectionPhaseMessage.toCar(): CarConnectionPhase =
    when (this) {
        CarConnectionPhaseMessage.DISCONNECTED -> CarConnectionPhase.DISCONNECTED
        CarConnectionPhaseMessage.CONNECTING -> CarConnectionPhase.CONNECTING
        CarConnectionPhaseMessage.HANDSHAKING -> CarConnectionPhase.HANDSHAKING
        CarConnectionPhaseMessage.CONNECTED -> CarConnectionPhase.CONNECTED
        CarConnectionPhaseMessage.FAILED -> CarConnectionPhase.FAILED
    }

private fun CarSignalDoubleMessage.toCar(): CarSignalInput =
    CarSignalInput(
        status =
            when (status) {
                CarSignalStatusMessage.LIVE -> CarSignalStatus.LIVE
                CarSignalStatusMessage.STALE -> CarSignalStatus.STALE
                CarSignalStatusMessage.UNSUPPORTED -> CarSignalStatus.UNSUPPORTED
                CarSignalStatusMessage.UNAVAILABLE -> CarSignalStatus.UNAVAILABLE
            },
        value = value,
    )

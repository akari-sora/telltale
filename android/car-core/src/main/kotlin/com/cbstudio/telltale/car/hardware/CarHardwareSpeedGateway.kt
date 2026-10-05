package com.cbstudio.telltale.car.hardware

/**
 * Gateway abstraction for listening to vehicle speed from host CarHardware (AA-05).
 */
interface CarHardwareSpeedGateway {
    fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit)
    fun stopListening()
}

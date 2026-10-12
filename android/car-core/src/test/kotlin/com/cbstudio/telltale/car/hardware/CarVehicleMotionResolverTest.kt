package com.cbstudio.telltale.car.hardware

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarSignalValue
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrame
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class CarVehicleMotionResolverTest {

    private lateinit var resolver: CarVehicleMotionResolver

    @Before
    fun setUp() {
        resolver = CarVehicleMotionResolver()
    }

    private fun liveFrame(speedKmh: Double): CarTelemetryFrame {
        val sig = CarSignalValue.sanitize(CarSignalStatus.LIVE, speedKmh, CarTelemetryFrame.SPEED_KMH_ENVELOPE)
        return CarTelemetryFrame(
            schemaVersion = 2,
            sequence = 1,
            connectionEpoch = 1,
            lifecycleEpoch = 0,
            producedAtMonotonicUs = 1_000,
            connectionPhase = CarConnectionPhase.CONNECTED,
            speedKmh = sig,
            rpm = sig,
            coolantC = sig,
            intakeAirC = sig,
            controlModuleVoltageV = sig,
            mapKpa = sig,
            diagnosticsAvailable = true,
            milOn = false,
            dtcCount = 0,
        )
    }

    @Test
    fun reverseMotionWithNegativeRawSpeedEvaluatesToMoving() {
        // AA05-15: Reverse raw speed < 0 is non-zero, hence MOVING
        val hostSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = -1.5f,
            displaySpeedMetersPerSecond = null,
        )
        val motion = resolver.resolveMotion(CarTelemetryState.Awaiting, hostSample)
        assertEquals(CarMotionEvidence.MOVING, motion)
    }

    @Test
    fun reverseMotionWithNegativeObdSpeedEvaluatesToMoving() {
        // SAFE-02: OBD negative speed (reverse) is non-zero, hence MOVING
        val obdReverse = CarTelemetryState.Current(liveFrame(-5.0), 1_000L)
        val motion = resolver.resolveMotion(obdReverse, CarHostSpeedSample.INITIAL)
        assertEquals(CarMotionEvidence.MOVING, motion)
    }

    @Test
    fun anyFreshNonZeroSourceEvaluatesToMoving() {
        // OBD says 0, but Host Display says 2.0 m/s -> MOVING
        val obdZero = CarTelemetryState.Current(liveFrame(0.0), 1_000L)
        val hostMoving = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 2.0f,
        )
        assertEquals(CarMotionEvidence.MOVING, resolver.resolveMotion(obdZero, hostMoving))

        // OBD says 5 km/h, Host says 0 m/s -> MOVING
        val obdMoving = CarTelemetryState.Current(liveFrame(5.0), 1_000L)
        val hostZero = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = 0.0f,
        )
        assertEquals(CarMotionEvidence.MOVING, resolver.resolveMotion(obdMoving, hostZero))

        // OBD says 0, but Host Raw says 0.5 m/s -> MOVING
        val hostRawMoving = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = 0.5f,
        )
        assertEquals(CarMotionEvidence.MOVING, resolver.resolveMotion(obdZero, hostRawMoving))
    }

    @Test
    fun allAvailableFreshSourcesZeroEvaluatesToStationary() {
        // Both OBD and Host report 0
        val obdZero = CarTelemetryState.Current(liveFrame(0.0), 1_000L)
        val hostZero = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = 0.0f,
        )
        assertEquals(CarMotionEvidence.STATIONARY, resolver.resolveMotion(obdZero, hostZero))

        // Only OBD reports 0, Host unavailable
        assertEquals(
            CarMotionEvidence.STATIONARY,
            resolver.resolveMotion(obdZero, CarHostSpeedSample.INITIAL),
        )

        // OBD unavailable, Host reports 0
        assertEquals(
            CarMotionEvidence.STATIONARY,
            resolver.resolveMotion(CarTelemetryState.Awaiting, hostZero),
        )
    }

    @Test
    fun noFreshEvidenceEvaluatesToUnknown() {
        // AA05-17: No fresh speed evidence -> UNKNOWN
        assertEquals(
            CarMotionEvidence.UNKNOWN,
            resolver.resolveMotion(CarTelemetryState.Awaiting, CarHostSpeedSample.INITIAL),
        )

        // Telemetry stale, Host stale
        val staleTelemetry = CarTelemetryState.Stale(1_000L, 2_000L)
        val staleHost = CarHostSpeedSample(status = CarHostSpeedStatus.STALE)
        assertEquals(
            CarMotionEvidence.UNKNOWN,
            resolver.resolveMotion(staleTelemetry, staleHost),
        )
    }

    @Test
    fun anyFiniteNonZeroSpeedEvaluatesToMoving() {
        val tinyPositiveSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = 0.0005f,
            displaySpeedMetersPerSecond = 0.0002f,
        )
        assertEquals(
            CarMotionEvidence.MOVING,
            resolver.resolveMotion(CarTelemetryState.Awaiting, tinyPositiveSample),
        )

        val tinyNegativeSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = -0.0005f,
            displaySpeedMetersPerSecond = null,
        )
        assertEquals(
            CarMotionEvidence.MOVING,
            resolver.resolveMotion(CarTelemetryState.Awaiting, tinyNegativeSample),
        )
    }

    @Test
    fun exactNegativeZeroTreatedAsStationary() {
        val negZeroSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = -0.0f,
            displaySpeedMetersPerSecond = 0.0f,
        )
        assertEquals(
            CarMotionEvidence.STATIONARY,
            resolver.resolveMotion(CarTelemetryState.Awaiting, negZeroSample),
        )
    }
}

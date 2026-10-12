package com.cbstudio.telltale.car.hardware

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarSignalValue
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrame
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class CarSpeedResolverTest {

    private lateinit var resolver: CarSpeedResolver

    @Before
    fun setUp() {
        resolver = CarSpeedResolver()
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

    private fun staleOrUnavailableFrame(status: CarSignalStatus): CarTelemetryFrame {
        val sig = CarSignalValue.sanitize(status, null, CarTelemetryFrame.SPEED_KMH_ENVELOPE)
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
    fun obdLiveSpeedTakesPrecedenceOverHostSpeeds() {
        val telemetryState = CarTelemetryState.Current(liveFrame(speedKmh = 60.0), 1_000L)
        val hostSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = 18f, // ~64.8 km/h
            displaySpeedMetersPerSecond = 19f, // ~68.4 km/h
        )

        val resolved = resolver.resolve(telemetryState, hostSample)

        assertEquals(CarSignalStatus.LIVE, resolved.status)
        assertEquals(60.0, resolved.speedKmh!!, 0.001)
        assertEquals(CarSpeedSource.OBD, resolved.source)
    }

    @Test
    fun obdUnavailableFallsBackToHostDisplaySpeed() {
        val telemetryState = CarTelemetryState.Current(staleOrUnavailableFrame(CarSignalStatus.UNAVAILABLE), 1_000L)
        val hostSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = 10f, // 36 km/h
            displaySpeedMetersPerSecond = 11f, // 39.6 km/h
        )

        val resolved = resolver.resolve(telemetryState, hostSample)

        assertEquals(CarSignalStatus.LIVE, resolved.status)
        assertEquals(39.6, resolved.speedKmh!!, 0.001)
        assertEquals(CarSpeedSource.HOST_DISPLAY, resolved.source)
    }

    @Test
    fun obdStaleFallsBackToHostDisplaySpeed() {
        val telemetryState = CarTelemetryState.Stale(1_000L, 2_000L)
        val hostSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 20f, // 72 km/h
        )

        val resolved = resolver.resolve(telemetryState, hostSample)

        assertEquals(CarSignalStatus.LIVE, resolved.status)
        assertEquals(72.0, resolved.speedKmh!!, 0.001)
        assertEquals(CarSpeedSource.HOST_DISPLAY, resolved.source)
    }

    @Test
    fun hostDisplaySpeedUnavailableFallsBackToHostRawSpeed() {
        val telemetryState = CarTelemetryState.Awaiting
        val hostSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = 25f, // 90 km/h
            displaySpeedMetersPerSecond = null,
        )

        val resolved = resolver.resolve(telemetryState, hostSample)

        assertEquals(CarSignalStatus.LIVE, resolved.status)
        assertEquals(90.0, resolved.speedKmh!!, 0.001)
        assertEquals(CarSpeedSource.HOST_RAW, resolved.source)
    }

    @Test
    fun zeroSpeedPreservedAccuratelyForObdAndHost() {
        // OBD 0 km/h
        val obdZero = resolver.resolve(
            CarTelemetryState.Current(liveFrame(0.0), 1_000L),
            CarHostSpeedSample.INITIAL,
        )
        assertEquals(CarSignalStatus.LIVE, obdZero.status)
        assertEquals(0.0, obdZero.speedKmh!!, 0.001)
        assertEquals(CarSpeedSource.OBD, obdZero.source)

        // Host Display 0 m/s
        val hostZero = resolver.resolve(
            CarTelemetryState.Awaiting,
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                displaySpeedMetersPerSecond = 0f,
            ),
        )
        assertEquals(CarSignalStatus.LIVE, hostZero.status)
        assertEquals(0.0, hostZero.speedKmh!!, 0.001)
        assertEquals(CarSpeedSource.HOST_DISPLAY, hostZero.source)
    }

    @Test
    fun neitherSourceAvailableReturnsUnavailableAndNeverFabricatesZero() {
        val resolved = resolver.resolve(
            CarTelemetryState.Awaiting,
            CarHostSpeedSample(status = CarHostSpeedStatus.UNAVAILABLE),
        )

        assertEquals(CarSignalStatus.UNAVAILABLE, resolved.status)
        assertNull(resolved.speedKmh)
        assertNull(resolved.source)
    }

    @Test
    fun eitherSourceStaleReturnsStaleAndNeverFabricatesZero() {
        val resolvedWithStaleHost = resolver.resolve(
            CarTelemetryState.Awaiting,
            CarHostSpeedSample(status = CarHostSpeedStatus.STALE),
        )
        assertEquals(CarSignalStatus.STALE, resolvedWithStaleHost.status)
        assertNull(resolvedWithStaleHost.speedKmh)

        val resolvedWithStaleTelemetry = resolver.resolve(
            CarTelemetryState.Stale(1_000L, 2_000L),
            CarHostSpeedSample(status = CarHostSpeedStatus.UNAVAILABLE),
        )
        assertEquals(CarSignalStatus.STALE, resolvedWithStaleTelemetry.status)
        assertNull(resolvedWithStaleTelemetry.speedKmh)
    }

    @Test
    fun nonFiniteValuesAreSafelySkipped() {
        val telemetryState = CarTelemetryState.Current(liveFrame(Double.NaN), 1_000L)
        val hostSample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = Float.POSITIVE_INFINITY,
            displaySpeedMetersPerSecond = Float.NaN,
        )

        val resolved = resolver.resolve(telemetryState, hostSample)
        assertEquals(CarSignalStatus.UNAVAILABLE, resolved.status)
        assertNull(resolved.speedKmh)
    }
}

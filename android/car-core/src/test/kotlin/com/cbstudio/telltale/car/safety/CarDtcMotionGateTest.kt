package com.cbstudio.telltale.car.safety

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CarDtcMotionGateTest {

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)
    private fun stale() = CarSignalInput(CarSignalStatus.STALE, null)
    private fun unavailable() = CarSignalInput(CarSignalStatus.UNAVAILABLE, null)

    private fun frameInput(
        speedKmh: CarSignalInput = live(0.0),
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
    ) = CarTelemetryFrameInput(
        schemaVersion = 1,
        sequence = 1,
        connectionEpoch = 1,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = phase,
        speedKmh = speedKmh,
        rpm = live(800.0),
        coolantC = live(90.0),
        intakeAirC = live(25.0),
        controlModuleVoltageV = live(14.0),
        mapKpa = live(35.0),
        diagnosticsAvailable = true,
        milOn = false,
        dtcCount = 0,
    )

    private fun TestScope.createRepository() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    @Test
    fun awaitingStateEvaluatesToUnknown() {
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(CarTelemetryState.Awaiting))
        assertFalse(CarDtcMotionGate.isStationary(CarTelemetryState.Awaiting))
    }

    @Test
    fun staleStateEvaluatesToUnknown() {
        val staleState = CarTelemetryState.Stale(1_000L, null)
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(staleState))
        assertFalse(CarDtcMotionGate.isStationary(staleState))
    }

    @Test
    fun incompatibleStateEvaluatesToUnknown() {
        val incompState = CarTelemetryState.Incompatible(2L)
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(incompState))
        assertFalse(CarDtcMotionGate.isStationary(incompState))
    }

    @Test
    fun disconnectedPhaseEvaluatesToUnknownEvenIfSpeedIsZero() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(speedKmh = live(0.0), phase = CarConnectionPhase.DISCONNECTED))

        val state = repo.state.value
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(state))
        assertFalse(CarDtcMotionGate.isStationary(state))
    }

    @Test
    fun speedZeroAndConnectedEvaluatesToStationary() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(speedKmh = live(0.0), phase = CarConnectionPhase.CONNECTED))

        val state = repo.state.value
        assertEquals(CarDtcMotionState.STATIONARY, CarDtcMotionGate.evaluate(state))
        assertTrue(CarDtcMotionGate.isStationary(state))
    }

    @Test
    fun positiveSpeedEvaluatesToMoving() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(speedKmh = live(5.0), phase = CarConnectionPhase.CONNECTED))

        val state = repo.state.value
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state))
        assertFalse(CarDtcMotionGate.isStationary(state))
    }

    @Test
    fun staleOrUnavailableSpeedEvaluatesToUnknown() = runTest {
        val repo = createRepository()

        repo.submit(frameInput(speedKmh = stale(), phase = CarConnectionPhase.CONNECTED))
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(repo.state.value))
        assertFalse(CarDtcMotionGate.isStationary(repo.state.value))

        repo.submit(frameInput(speedKmh = unavailable(), phase = CarConnectionPhase.CONNECTED))
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(repo.state.value))
        assertFalse(CarDtcMotionGate.isStationary(repo.state.value))
    }

    @Test
    fun nonFiniteOrNegativeSpeedEvaluatesToUnknown() = runTest {
        val repo = createRepository()

        repo.submit(frameInput(speedKmh = live(Double.NaN), phase = CarConnectionPhase.CONNECTED))
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(repo.state.value))

        repo.submit(frameInput(speedKmh = live(-1.0), phase = CarConnectionPhase.CONNECTED))
        assertEquals(CarDtcMotionState.UNKNOWN, CarDtcMotionGate.evaluate(repo.state.value))
    }
}

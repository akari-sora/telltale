package com.cbstudio.telltale.car.safety

import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.hardware.CarHostSpeedStatus
import com.cbstudio.telltale.car.hardware.CarMotionEvidence
import com.cbstudio.telltale.car.hardware.CarVehicleMotionResolver
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

/**
 * Adversarial empirical challenge suite for [CarDtcMotionGate] and [CarVehicleMotionResolver].
 *
 * Designed to stress-test:
 * 1. Negative speed edge cases (-1.0, -0.0001, -50.0, -100.0, subnormals, out-of-envelope).
 * 2. IEEE 754 negative zero (-0.0, -0.0f) in OBD and host channels.
 * 3. Host speed status variations (LIVE, STALE, UNAVAILABLE, UNIMPLEMENTED, PERMISSION_DENIED).
 * 4. Non-connected phase speed inputs (DISCONNECTED, CONNECTING, HANDSHAKING, FAILED).
 * 5. Combinatorial matrix search verifying that NO input combination can trick the gate
 *    into returning STATIONARY while in reverse or forward motion.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class CarDtcMotionGateAdversarialStressTest {

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)
    private fun stale() = CarSignalInput(CarSignalStatus.STALE, null)
    private fun unavailable() = CarSignalInput(CarSignalStatus.UNAVAILABLE, null)

    private var seq = 0L

    private fun frameInput(
        speedKmh: CarSignalInput = live(0.0),
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
    ) = CarTelemetryFrameInput(
        schemaVersion = 2,
        sequence = ++seq,
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

    // =========================================================================
    // 1. Negative Speeds (-1.0, -0.0001, -50.0, boundary & subnormals)
    // =========================================================================

    @Test
    fun reverseSpeedValuesEvaluateToMovingInConnectedPhase() = runTest {
        val repo = createRepository()
        val testSpeeds = listOf(-1.0, -0.0001, -50.0, -15.0, -100.0, -0.0000001, -Double.MIN_VALUE)

        for (speed in testSpeeds) {
            repo.submit(frameInput(speedKmh = live(speed), phase = CarConnectionPhase.CONNECTED))
            val state = repo.state.value

            assertEquals(
                "Speed $speed must evaluate to MOVING",
                CarDtcMotionState.MOVING,
                CarDtcMotionGate.evaluate(state)
            )
            assertFalse(
                "Speed $speed must not be stationary",
                CarDtcMotionGate.isStationary(state)
            )
        }
    }

    @Test
    fun outOfEnvelopeNegativeSpeedEvaluatesToUnknownNotStationary() = runTest {
        val repo = createRepository()
        // Speeds beyond SPEED_KMH_ENVELOPE (-100.0..400.0) are sanitized to UNAVAILABLE
        val outOfBoundsSpeeds = listOf(-100.0001, -150.0, -500.0)

        for (speed in outOfBoundsSpeeds) {
            repo.submit(frameInput(speedKmh = live(speed), phase = CarConnectionPhase.CONNECTED))
            val state = repo.state.value

            assertEquals(
                "Out-of-envelope speed $speed must evaluate to UNKNOWN",
                CarDtcMotionState.UNKNOWN,
                CarDtcMotionGate.evaluate(state)
            )
            assertFalse(
                "Out-of-envelope speed $speed must NOT be stationary",
                CarDtcMotionGate.isStationary(state)
            )
        }
    }

    // =========================================================================
    // 2. IEEE 754 Negative Zero (-0.0, -0.0f)
    // =========================================================================

    @Test
    fun ieeeNegativeZeroEvaluatesToStationaryInBothObdAndHost() = runTest {
        val repo = createRepository()

        // OBD -0.0
        repo.submit(frameInput(speedKmh = live(-0.0), phase = CarConnectionPhase.CONNECTED))
        var state = repo.state.value
        assertEquals(CarDtcMotionState.STATIONARY, CarDtcMotionGate.evaluate(state))
        assertTrue(CarDtcMotionGate.isStationary(state))

        // OBD 0.0 with Host -0.0f (both raw and display)
        val hostNegZero = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = -0.0f,
            displaySpeedMetersPerSecond = -0.0f,
        )
        repo.submit(frameInput(speedKmh = live(0.0), phase = CarConnectionPhase.CONNECTED))
        state = repo.state.value
        assertEquals(CarDtcMotionState.STATIONARY, CarDtcMotionGate.evaluate(state, hostNegZero))
        assertTrue(CarDtcMotionGate.isStationary(state, hostNegZero))

        // OBD Awaiting with Host -0.0f
        assertEquals(
            CarDtcMotionState.STATIONARY,
            CarDtcMotionGate.evaluate(CarTelemetryState.Awaiting, hostNegZero)
        )
        assertTrue(CarDtcMotionGate.isStationary(CarTelemetryState.Awaiting, hostNegZero))
    }

    // =========================================================================
    // 3. Host Speed Status Variations
    // =========================================================================

    @Test
    fun nonLiveHostSpeedStatusWithNegativeSpeedNeverPermitsStationaryWithoutValidObd() {
        val nonLiveStatuses = listOf(
            CarHostSpeedStatus.STALE,
            CarHostSpeedStatus.UNAVAILABLE,
            CarHostSpeedStatus.UNIMPLEMENTED,
            CarHostSpeedStatus.PERMISSION_DENIED,
        )

        for (status in nonLiveStatuses) {
            val sample = CarHostSpeedSample(
                status = status,
                rawMetersPerSecond = -1.0f,
                displaySpeedMetersPerSecond = -1.0f,
            )
            // Telemetry awaiting: gate must be UNKNOWN, never STATIONARY
            val result = CarDtcMotionGate.evaluate(CarTelemetryState.Awaiting, sample)
            assertEquals("Status $status must evaluate to UNKNOWN", CarDtcMotionState.UNKNOWN, result)
            assertFalse(CarDtcMotionGate.isStationary(CarTelemetryState.Awaiting, sample))
        }
    }

    @Test
    fun liveHostSpeedWithMismatchedRawAndDisplayReverseEvaluatesToMoving() = runTest {
        val repo = createRepository()
        repo.submit(frameInput(speedKmh = live(0.0), phase = CarConnectionPhase.CONNECTED))
        val state = repo.state.value

        // display = 0, raw = -1.0 (reverse in raw only)
        val sample1 = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = -1.0f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state, sample1))
        assertFalse(CarDtcMotionGate.isStationary(state, sample1))

        // display = 0, raw = -0.0001 (tiny reverse in raw only)
        val sample2 = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = -0.0001f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state, sample2))
        assertFalse(CarDtcMotionGate.isStationary(state, sample2))

        // display = 0, raw = -50.0 (high reverse in raw only)
        val sample3 = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = -50.0f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state, sample3))
        assertFalse(CarDtcMotionGate.isStationary(state, sample3))

        // display = -1.0, raw = 0.0 (reverse in display only)
        val sample4 = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = -1.0f,
            rawMetersPerSecond = 0.0f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state, sample4))
        assertFalse(CarDtcMotionGate.isStationary(state, sample4))

        // display = null, raw = -1.0 (null display, raw reverse)
        val sample5 = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = null,
            rawMetersPerSecond = -1.0f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state, sample5))
        assertFalse(CarDtcMotionGate.isStationary(state, sample5))

        // display = -1.0, raw = null (display reverse, null raw)
        val sample6 = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = -1.0f,
            rawMetersPerSecond = null,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(state, sample6))
        assertFalse(CarDtcMotionGate.isStationary(state, sample6))
    }

    // =========================================================================
    // 4. Non-Connected Phase Speed Inputs
    // =========================================================================

    @Test
    fun nonConnectedPhasesRejectStationaryUnlessHostLiveZero() = runTest {
        val repo = createRepository()
        val nonConnectedPhases = listOf(
            CarConnectionPhase.DISCONNECTED,
            CarConnectionPhase.CONNECTING,
            CarConnectionPhase.HANDSHAKING,
            CarConnectionPhase.FAILED,
        )

        for (phase in nonConnectedPhases) {
            // Case A: OBD reports 0.0, but phase is non-connected and Host is UNAVAILABLE
            repo.submit(frameInput(speedKmh = live(0.0), phase = phase))
            var state = repo.state.value

            assertEquals(
                "Phase $phase without host speed must be UNKNOWN",
                CarDtcMotionState.UNKNOWN,
                CarDtcMotionGate.evaluate(state, CarHostSpeedSample.INITIAL)
            )
            assertFalse(
                "Phase $phase must not be stationary without live host zero",
                CarDtcMotionGate.isStationary(state, CarHostSpeedSample.INITIAL)
            )

            // Case B: OBD reports 0.0, phase is non-connected, Host reports LIVE strictly 0.0
            val hostZero = CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                displaySpeedMetersPerSecond = 0.0f,
                rawMetersPerSecond = 0.0f,
            )
            assertEquals(
                "Phase $phase with live host 0.0 evaluates to STATIONARY",
                CarDtcMotionState.STATIONARY,
                CarDtcMotionGate.evaluate(state, hostZero)
            )
            assertTrue(
                "Phase $phase with live host 0.0 must be stationary",
                CarDtcMotionGate.isStationary(state, hostZero)
            )

            // Case C: OBD reports 0.0, phase is non-connected, Host reports LIVE reverse (-1.0, -0.0001, -50.0)
            val reverseRawSamples = listOf(-1.0f, -0.0001f, -50.0f)
            for (rev in reverseRawSamples) {
                val hostReverse = CarHostSpeedSample(
                    status = CarHostSpeedStatus.LIVE,
                    displaySpeedMetersPerSecond = 0.0f,
                    rawMetersPerSecond = rev,
                )
                assertEquals(
                    "Phase $phase with host raw $rev must evaluate to MOVING",
                    CarDtcMotionState.MOVING,
                    CarDtcMotionGate.evaluate(state, hostReverse)
                )
                assertFalse(
                    "Phase $phase with host raw $rev must NOT be stationary",
                    CarDtcMotionGate.isStationary(state, hostReverse)
                )
            }

            // Case D: OBD reports reverse (-1.0, -0.0001, -50.0) in non-connected phase
            val reverseObdSpeeds = listOf(-1.0, -0.0001, -50.0)
            for (revObd in reverseObdSpeeds) {
                repo.submit(frameInput(speedKmh = live(revObd), phase = phase))
                state = repo.state.value

                assertEquals(
                    "Phase $phase with OBD $revObd must evaluate to MOVING",
                    CarDtcMotionState.MOVING,
                    CarDtcMotionGate.evaluate(state, hostZero)
                )
                assertFalse(
                    "Phase $phase with OBD $revObd must NOT be stationary",
                    CarDtcMotionGate.isStationary(state, hostZero)
                )
            }
        }
    }

    // =========================================================================
    // 5. Property-Based Combinatorial Invariant Check
    // =========================================================================

    @Test
    fun exhaustiveCombinatorialStressTestGuaranteesNeverStationaryWhenMoving() = runTest {
        val repo = createRepository()

        val obdSpeeds = listOf(-50.0, -1.0, -0.0001, -0.0, 0.0, 0.0001, 1.0, 50.0)
        val phases = listOf(
            CarConnectionPhase.CONNECTED,
            CarConnectionPhase.DISCONNECTED,
            CarConnectionPhase.CONNECTING,
            CarConnectionPhase.HANDSHAKING,
            CarConnectionPhase.FAILED,
        )
        val hostStatuses = listOf(
            CarHostSpeedStatus.LIVE,
            CarHostSpeedStatus.STALE,
            CarHostSpeedStatus.UNAVAILABLE,
            CarHostSpeedStatus.UNIMPLEMENTED,
            CarHostSpeedStatus.PERMISSION_DENIED,
        )
        val hostDisplaySpeeds = listOf(null, -50.0f, -1.0f, -0.0001f, -0.0f, 0.0f, 0.0001f, 1.0f, 50.0f)
        val hostRawSpeeds = listOf(null, -50.0f, -1.0f, -0.0001f, -0.0f, 0.0f, 0.0001f, 1.0f, 50.0f)

        var testedCombinations = 0

        for (phase in phases) {
            for (obdSpeed in obdSpeeds) {
                repo.submit(frameInput(speedKmh = live(obdSpeed), phase = phase))
                val state = repo.state.value

                for (hostStatus in hostStatuses) {
                    for (hDisplay in hostDisplaySpeeds) {
                        for (hRaw in hostRawSpeeds) {
                            val hostSample = CarHostSpeedSample(
                                status = hostStatus,
                                displaySpeedMetersPerSecond = hDisplay,
                                rawMetersPerSecond = hRaw,
                            )

                            val isStationary = CarDtcMotionGate.isStationary(state, hostSample)
                            val motionState = CarDtcMotionGate.evaluate(state, hostSample)

                            // Mathematical Truth: Is vehicle actually moving?
                            val obdMoving = (obdSpeed != 0.0 && obdSpeed != -0.0)
                            val hostMoving = (hostStatus == CarHostSpeedStatus.LIVE && (
                                (hDisplay != null && hDisplay != 0.0f && hDisplay != -0.0f) ||
                                (hRaw != null && hRaw != 0.0f && hRaw != -0.0f)
                            ))

                            val vehicleInMotion = obdMoving || hostMoving

                            if (vehicleInMotion) {
                                assertFalse(
                                    "VIOLATION: Returned isStationary=true while vehicle in motion! " +
                                        "obd=$obdSpeed phase=$phase hostStatus=$hostStatus display=$hDisplay raw=$hRaw",
                                    isStationary
                                )
                                assertEquals(
                                    "VIOLATION: Returned $motionState instead of MOVING while vehicle in motion! " +
                                        "obd=$obdSpeed phase=$phase hostStatus=$hostStatus display=$hDisplay raw=$hRaw",
                                    CarDtcMotionState.MOVING,
                                    motionState
                                )
                            }

                            if (isStationary) {
                                assertEquals(CarDtcMotionState.STATIONARY, motionState)
                                assertFalse("Must not be in motion if stationary", vehicleInMotion)
                            }

                            testedCombinations++
                        }
                    }
                }
            }
        }

        assertTrue("Must have tested extensive combinations", testedCombinations >= 10_000)
    }

    // =========================================================================
    // 6. Comprehensive Matrix of Explicit Edge Cases
    // =========================================================================

    @Test
    fun exhaustiveMatrixOfExplicitEdgeCases() = runTest {
        val repo = createRepository()

        // Helper to get state
        fun getState(speed: Double?, status: CarSignalStatus, phase: CarConnectionPhase): CarTelemetryState {
            val signal = if (speed != null) CarSignalInput(status, speed) else CarSignalInput(status, null)
            repo.submit(frameInput(speedKmh = signal, phase = phase))
            return repo.state.value
        }

        // 1. Float.MIN_VALUE in host display
        val sampleMinValDisplay = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = Float.MIN_VALUE,
            rawMetersPerSecond = 0.0f,
        )
        assertEquals(
            CarDtcMotionState.MOVING,
            CarDtcMotionGate.evaluate(CarTelemetryState.Awaiting, sampleMinValDisplay)
        )
        assertFalse(CarDtcMotionGate.isStationary(CarTelemetryState.Awaiting, sampleMinValDisplay))

        // 2. -Float.MIN_VALUE in host raw
        val sampleNegMinValRaw = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = -Float.MIN_VALUE,
        )
        assertEquals(
            CarDtcMotionState.MOVING,
            CarDtcMotionGate.evaluate(CarTelemetryState.Awaiting, sampleNegMinValRaw)
        )
        assertFalse(CarDtcMotionGate.isStationary(CarTelemetryState.Awaiting, sampleNegMinValRaw))

        // 3. Double.MIN_VALUE in OBD
        val stateMinValObd = getState(Double.MIN_VALUE, CarSignalStatus.LIVE, CarConnectionPhase.CONNECTED)
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(stateMinValObd))
        assertFalse(CarDtcMotionGate.isStationary(stateMinValObd))

        // 4. -Double.MIN_VALUE in OBD
        val stateNegMinValObd = getState(-Double.MIN_VALUE, CarSignalStatus.LIVE, CarConnectionPhase.CONNECTED)
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(stateNegMinValObd))
        assertFalse(CarDtcMotionGate.isStationary(stateNegMinValObd))

        // 5. Host raw reverse (-0.0001) with OBD connected zero
        val stateConnectedZero = getState(0.0, CarSignalStatus.LIVE, CarConnectionPhase.CONNECTED)
        val sampleTinyReverse = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = null,
            rawMetersPerSecond = -0.0001f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(stateConnectedZero, sampleTinyReverse))
        assertFalse(CarDtcMotionGate.isStationary(stateConnectedZero, sampleTinyReverse))

        // 6. OBD reverse (-0.0001) with Host zero
        val stateConnectedTinyRev = getState(-0.0001, CarSignalStatus.LIVE, CarConnectionPhase.CONNECTED)
        val hostZero = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = 0.0f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(stateConnectedTinyRev, hostZero))
        assertFalse(CarDtcMotionGate.isStationary(stateConnectedTinyRev, hostZero))

        // 7. Non-connected phase with display = 0f, raw = null is unknown
        val stateDisconnectedZero = getState(0.0, CarSignalStatus.LIVE, CarConnectionPhase.DISCONNECTED)
        val hostDisplayZeroOnly = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = null,
        )
        assertEquals(
            CarDtcMotionState.UNKNOWN,
            CarDtcMotionGate.evaluate(stateDisconnectedZero, hostDisplayZeroOnly)
        )
        assertFalse(CarDtcMotionGate.isStationary(stateDisconnectedZero, hostDisplayZeroOnly))

        // 8. Non-connected phase with display = null, raw = 0f is unknown
        val hostRawZeroOnly = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = null,
            rawMetersPerSecond = 0.0f,
        )
        assertEquals(
            CarDtcMotionState.UNKNOWN,
            CarDtcMotionGate.evaluate(stateDisconnectedZero, hostRawZeroOnly)
        )
        assertFalse(CarDtcMotionGate.isStationary(stateDisconnectedZero, hostRawZeroOnly))

        // 9. Non-connected phase with display = 0f, raw = -0.0001f
        val hostDisplayZeroRawRev = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            displaySpeedMetersPerSecond = 0.0f,
            rawMetersPerSecond = -0.0001f,
        )
        assertEquals(
            CarDtcMotionState.MOVING,
            CarDtcMotionGate.evaluate(stateDisconnectedZero, hostDisplayZeroRawRev)
        )
        assertFalse(CarDtcMotionGate.isStationary(stateDisconnectedZero, hostDisplayZeroRawRev))

        // 10. Incompatible state with host reverse
        val incompState = CarTelemetryState.Incompatible(99L)
        val hostRev = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = -1.0f,
        )
        assertEquals(CarDtcMotionState.MOVING, CarDtcMotionGate.evaluate(incompState, hostRev))
        assertFalse(CarDtcMotionGate.isStationary(incompState, hostRev))
    }
}

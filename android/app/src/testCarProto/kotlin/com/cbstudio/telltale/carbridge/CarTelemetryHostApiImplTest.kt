package com.cbstudio.telltale.carbridge

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarSignalValue
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import com.cbstudio.telltale.carbridge.generated.CarConnectionPhaseMessage
import com.cbstudio.telltale.carbridge.generated.CarSignalDoubleMessage
import com.cbstudio.telltale.carbridge.generated.CarSignalStatusMessage
import com.cbstudio.telltale.carbridge.generated.CarTelemetryMessage
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CarTelemetryHostApiImplTest {

    private fun signal(status: CarSignalStatusMessage, value: Double? = null) =
        CarSignalDoubleMessage(status = status, value = value)

    private fun message(
        schemaVersion: Long = 2,
        sequence: Long = 1,
        connectionEpoch: Long = 3,
        phase: CarConnectionPhaseMessage = CarConnectionPhaseMessage.CONNECTED,
    ) = CarTelemetryMessage(
        schemaVersion = schemaVersion,
        sequence = sequence,
        connectionEpoch = connectionEpoch,
        lifecycleEpoch = 2,
        producedAtMonotonicUs = 123_456,
        connectionPhase = phase,
        speedKmh = signal(CarSignalStatusMessage.LIVE, 88.0),
        rpm = signal(CarSignalStatusMessage.STALE),
        coolantC = signal(CarSignalStatusMessage.UNSUPPORTED),
        intakeAirC = signal(CarSignalStatusMessage.UNAVAILABLE),
        controlModuleVoltageV = signal(CarSignalStatusMessage.LIVE, 13.8),
        mapKpa = signal(CarSignalStatusMessage.LIVE, 101.0),
        engineLoadPct = signal(CarSignalStatusMessage.LIVE, 67.5),
        diagnosticsAvailable = true,
        milOn = null,
        dtcCount = 2,
    )

    private fun TestScope.repository() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    @Test
    fun decodesEveryFieldIntoRepositoryCurrent() = runTest {
        val repo = repository()
        val api = CarTelemetryHostApiImpl(repo)

        api.publishTelemetryFrame(message())

        val state = repo.state.value
        assertTrue("expected Current, was $state", state is CarTelemetryState.Current)
        val frame = (state as CarTelemetryState.Current).frame
        assertEquals(2L, frame.schemaVersion)
        assertEquals(1L, frame.sequence)
        assertEquals(3L, frame.connectionEpoch)
        assertEquals(2L, frame.lifecycleEpoch)
        assertEquals(123_456L, frame.producedAtMonotonicUs)
        assertEquals(CarConnectionPhase.CONNECTED, frame.connectionPhase)
        assertEquals(CarSignalStatus.LIVE, frame.speedKmh.status)
        assertEquals(88.0, frame.speedKmh.value!!, 0.0)
        assertEquals(CarSignalValue.STALE, frame.rpm)
        assertEquals(CarSignalValue.UNSUPPORTED, frame.coolantC)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.intakeAirC)
        assertEquals(13.8, frame.controlModuleVoltageV.value!!, 0.0)
        assertEquals(101.0, frame.mapKpa.value!!, 0.0)
        assertEquals(67.5, frame.engineLoadPct.value!!, 0.0)
        assertTrue(frame.diagnosticsAvailable)
        assertNull(frame.milOn)
        assertEquals(2L, frame.dtcCount)
    }

    @Test
    fun everyPhaseMapsOneToOne() = runTest {
        val repo = repository()
        val api = CarTelemetryHostApiImpl(repo)
        val expected =
            mapOf(
                CarConnectionPhaseMessage.DISCONNECTED to CarConnectionPhase.DISCONNECTED,
                CarConnectionPhaseMessage.CONNECTING to CarConnectionPhase.CONNECTING,
                CarConnectionPhaseMessage.HANDSHAKING to CarConnectionPhase.HANDSHAKING,
                CarConnectionPhaseMessage.CONNECTED to CarConnectionPhase.CONNECTED,
                CarConnectionPhaseMessage.FAILED to CarConnectionPhase.FAILED,
            )
        assertEquals(CarConnectionPhaseMessage.entries.size, expected.size)
        var sequence = 1L
        for ((message, phase) in expected) {
            api.publishTelemetryFrame(message(sequence = sequence++, phase = message))
            val state = repo.state.value as CarTelemetryState.Current
            assertEquals(phase, state.frame.connectionPhase)
        }
    }

    @Test
    fun schemaMismatchReachesRepositoryAsIncompatible() = runTest {
        val repo = repository()
        CarTelemetryHostApiImpl(repo).publishTelemetryFrame(message(schemaVersion = 3))
        assertEquals(CarTelemetryState.Incompatible(3), repo.state.value)
    }

    // AA02-28 through the adapter: a new engine registration is a new producer.
    @Test
    fun constructingAdapterReattachesProducer() = runTest {
        val repo = repository()
        CarTelemetryHostApiImpl(repo).publishTelemetryFrame(message(sequence = 500))
        assertTrue(repo.state.value is CarTelemetryState.Current)

        val restarted = CarTelemetryHostApiImpl(repo)
        assertEquals(CarTelemetryState.Awaiting, repo.state.value)

        restarted.publishTelemetryFrame(message(sequence = 1))
        assertEquals(1L, (repo.state.value as CarTelemetryState.Current).frame.sequence)
    }
}

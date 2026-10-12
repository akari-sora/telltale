package com.cbstudio.telltale.car.telemetry

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CarTelemetryRepositoryTest {

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)

    private fun input(
        schemaVersion: Long = 2,
        sequence: Long = 1,
        connectionEpoch: Long = 1,
        lifecycleEpoch: Long = 0,
        producedAtMonotonicUs: Long = 1_000,
        phase: CarConnectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh: CarSignalInput = live(42.0),
        rpm: CarSignalInput = live(1800.0),
        coolantC: CarSignalInput = live(90.0),
        intakeAirC: CarSignalInput = live(25.0),
        controlModuleVoltageV: CarSignalInput = live(14.1),
        mapKpa: CarSignalInput = live(35.0),
        engineLoadPct: CarSignalInput = live(50.0),
        diagnosticsAvailable: Boolean = false,
        milOn: Boolean? = null,
        dtcCount: Long? = null,
    ) = CarTelemetryFrameInput(
        schemaVersion = schemaVersion,
        sequence = sequence,
        connectionEpoch = connectionEpoch,
        lifecycleEpoch = lifecycleEpoch,
        producedAtMonotonicUs = producedAtMonotonicUs,
        connectionPhase = phase,
        speedKmh = speedKmh,
        rpm = rpm,
        coolantC = coolantC,
        intakeAirC = intakeAirC,
        controlModuleVoltageV = controlModuleVoltageV,
        mapKpa = mapKpa,
        engineLoadPct = engineLoadPct,
        diagnosticsAvailable = diagnosticsAvailable,
        milOn = milOn,
        dtcCount = dtcCount,
    )

    private fun TestScope.repository() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    private fun CarTelemetryRepository.currentFrame(): CarTelemetryFrame {
        val state = state.value
        assertTrue("expected Current, was $state", state is CarTelemetryState.Current)
        return (state as CarTelemetryState.Current).frame
    }

    // AA02-22
    @Test
    fun startsAwaitingAndAcceptsV2FrameIntoCurrent() = runTest {
        val repo = repository()
        assertEquals(CarTelemetryState.Awaiting, repo.state.value)

        advanceTimeBy(500)
        assertEquals(CarTelemetrySubmitResult.ACCEPTED, repo.submit(input()))

        val state = repo.state.value as CarTelemetryState.Current
        assertEquals(500L, state.receivedAtElapsedMs)
        assertEquals(2L, state.frame.schemaVersion)
        assertEquals(CarConnectionPhase.CONNECTED, state.frame.connectionPhase)
        assertEquals(CarSignalStatus.LIVE, state.frame.speedKmh.status)
        assertEquals(42.0, state.frame.speedKmh.value!!, 0.0)
        assertEquals(1800.0, state.frame.rpm.value!!, 0.0)
        assertEquals(14.1, state.frame.controlModuleVoltageV.value!!, 0.0)
        assertEquals(35.0, state.frame.mapKpa.value!!, 0.0)
        assertEquals(50.0, state.frame.engineLoadPct.value!!, 0.0)
    }

    // AA02-23
    @Test
    fun schemaMismatchIsIncompatibleWithNoDisplayableNumbers() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 1))

        assertEquals(
            CarTelemetrySubmitResult.INCOMPATIBLE_SCHEMA,
            repo.submit(input(schemaVersion = 3, sequence = 2)),
        )
        val state = repo.state.value
        assertEquals(CarTelemetryState.Incompatible(3), state)

        // Incompatible cancels the stale timer: it must not decay into Stale
        // (which would suggest the bridge simply went quiet).
        advanceTimeBy(10_000)
        runCurrent()
        assertEquals(CarTelemetryState.Incompatible(3), repo.state.value)

        // The next valid v2 frame recovers.
        assertEquals(CarTelemetrySubmitResult.ACCEPTED, repo.submit(input(sequence = 3)))
        assertTrue(repo.state.value is CarTelemetryState.Current)
    }

    @Test
    fun schemaZeroIsAlsoIncompatible() = runTest {
        val repo = repository()
        repo.submit(input(schemaVersion = 0))
        assertEquals(CarTelemetryState.Incompatible(0), repo.state.value)
    }

    // AA02-24
    @Test
    fun duplicateAndOutOfOrderSequencesAreDropped() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 5, speedKmh = live(10.0)))

        assertEquals(
            CarTelemetrySubmitResult.DROPPED_OUT_OF_ORDER_SEQUENCE,
            repo.submit(input(sequence = 5, speedKmh = live(99.0))),
        )
        assertEquals(
            CarTelemetrySubmitResult.DROPPED_OUT_OF_ORDER_SEQUENCE,
            repo.submit(input(sequence = 4, speedKmh = live(98.0))),
        )
        assertEquals(10.0, repo.currentFrame().speedKmh.value!!, 0.0)

        // Gaps are fine: the producer coalesces and may skip.
        assertEquals(CarTelemetrySubmitResult.ACCEPTED, repo.submit(input(sequence = 9)))
    }

    @Test
    fun olderConnectionEpochIsDropped() = runTest {
        val repo = repository()
        repo.submit(input(connectionEpoch = 3, sequence = 1))
        assertEquals(
            CarTelemetrySubmitResult.DROPPED_OLD_CONNECTION_EPOCH,
            repo.submit(input(connectionEpoch = 2, sequence = 100)),
        )
        assertEquals(3L, repo.currentFrame().connectionEpoch)
    }

    // AA02-25
    @Test
    fun newerConnectionEpochStartsFreshSequenceDomain() = runTest {
        val repo = repository()
        repo.submit(input(connectionEpoch = 1, sequence = 50))

        assertEquals(
            CarTelemetrySubmitResult.ACCEPTED,
            repo.submit(input(connectionEpoch = 2, sequence = 1)),
        )
        assertEquals(2L, repo.currentFrame().connectionEpoch)
        assertEquals(
            CarTelemetrySubmitResult.DROPPED_OUT_OF_ORDER_SEQUENCE,
            repo.submit(input(connectionEpoch = 2, sequence = 1)),
        )
        assertEquals(
            CarTelemetrySubmitResult.ACCEPTED,
            repo.submit(input(connectionEpoch = 2, sequence = 2)),
        )
    }

    @Test
    fun lifecycleRegressionWithinOneConnectionEpochIsDropped() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 1, lifecycleEpoch = 4))
        assertEquals(
            CarTelemetrySubmitResult.DROPPED_LIFECYCLE_REGRESSION,
            repo.submit(input(sequence = 2, lifecycleEpoch = 3)),
        )
        assertEquals(
            CarTelemetrySubmitResult.ACCEPTED,
            repo.submit(input(sequence = 3, lifecycleEpoch = 4)),
        )
        // A new connection epoch may carry any non-negative lifecycle epoch.
        assertEquals(
            CarTelemetrySubmitResult.ACCEPTED,
            repo.submit(input(connectionEpoch = 2, sequence = 1, lifecycleEpoch = 0)),
        )
    }

    @Test
    fun malformedHeaderIsDroppedWithoutStateChange() = runTest {
        val repo = repository()
        for (bad in listOf(
            input(sequence = -1),
            input(connectionEpoch = -1),
            input(lifecycleEpoch = -1),
            input(producedAtMonotonicUs = -1),
        )) {
            assertEquals(CarTelemetrySubmitResult.DROPPED_MALFORMED_HEADER, repo.submit(bad))
            assertEquals(CarTelemetryState.Awaiting, repo.state.value)
        }
    }

    // AA02-26
    @Test
    fun invalidNumericSignalsAreSanitizedIndependently() = runTest {
        val repo = repository()
        repo.submit(
            input(
                speedKmh = live(Double.NaN),
                rpm = live(Double.POSITIVE_INFINITY),
                coolantC = live(301.0),
                intakeAirC = live(-80.1),
                controlModuleVoltageV = live(60.0),
                mapKpa = CarSignalInput(CarSignalStatus.LIVE, null),
                engineLoadPct = live(100.1),
            ),
        )
        val frame = repo.currentFrame()
        assertEquals(CarSignalValue.UNAVAILABLE, frame.speedKmh)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.rpm)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.coolantC)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.intakeAirC)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.mapKpa)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.engineLoadPct)
        // Envelope bounds are inclusive; a valid signal survives next to bad ones.
        assertEquals(CarSignalStatus.LIVE, frame.controlModuleVoltageV.status)
        assertEquals(60.0, frame.controlModuleVoltageV.value!!, 0.0)
    }

    @Test
    fun engineLoadRequiresAFinitePercentageInsideInclusiveBounds() = runTest {
        val repo = repository()
        var sequence = 1L
        for (bad in listOf(Double.NaN, Double.NEGATIVE_INFINITY, -0.1, 100.1)) {
            repo.submit(input(sequence = sequence++, engineLoadPct = live(bad)))
            assertEquals(CarSignalValue.UNAVAILABLE, repo.currentFrame().engineLoadPct)
        }
        repo.submit(input(sequence = sequence++, engineLoadPct = live(0.0)))
        assertEquals(0.0, repo.currentFrame().engineLoadPct.value!!, 0.0)
        repo.submit(input(sequence = sequence, engineLoadPct = live(100.0)))
        assertEquals(100.0, repo.currentFrame().engineLoadPct.value!!, 0.0)
    }

    // AA02-15 (host side of the two-sided invariant)
    @Test
    fun nonLiveStatusNeverCarriesANumber() = runTest {
        val repo = repository()
        repo.submit(
            input(
                speedKmh = CarSignalInput(CarSignalStatus.STALE, 50.0),
                rpm = CarSignalInput(CarSignalStatus.UNSUPPORTED, 900.0),
                coolantC = CarSignalInput(CarSignalStatus.UNAVAILABLE, 80.0),
            ),
        )
        val frame = repo.currentFrame()
        assertEquals(CarSignalValue.STALE, frame.speedKmh)
        assertNull(frame.speedKmh.value)
        assertEquals(CarSignalValue.UNSUPPORTED, frame.rpm)
        assertNull(frame.rpm.value)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.coolantC)
        assertNull(frame.coolantC.value)
        for (signal in listOf(
            frame.speedKmh, frame.rpm, frame.coolantC, frame.intakeAirC,
            frame.controlModuleVoltageV, frame.mapKpa,
            frame.engineLoadPct,
        )) {
            assertEquals(signal.status == CarSignalStatus.LIVE, signal.value != null)
        }
    }

    @Test
    fun diagnosticsUnavailableForcesNullMilAndCount() = runTest {
        val repo = repository()
        repo.submit(input(diagnosticsAvailable = false, milOn = true, dtcCount = 3))
        val frame = repo.currentFrame()
        assertNull(frame.milOn)
        assertNull(frame.dtcCount)
    }

    @Test
    fun diagnosticsPreserveCountAndUnknownMil() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 1, diagnosticsAvailable = true, milOn = null, dtcCount = 0))
        assertNull(repo.currentFrame().milOn)
        assertEquals(0L, repo.currentFrame().dtcCount)

        repo.submit(input(sequence = 2, diagnosticsAvailable = true, milOn = false, dtcCount = 65_536))
        assertEquals(false, repo.currentFrame().milOn)
        assertNull(repo.currentFrame().dtcCount)

        repo.submit(input(sequence = 3, diagnosticsAvailable = true, milOn = true, dtcCount = -1))
        assertNull(repo.currentFrame().dtcCount)
    }

    // AA02-27
    @Test
    fun goesStaleAfterThreeSecondsWithoutAcceptedFrame() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 1, connectionEpoch = 7))

        advanceTimeBy(2_999)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Current)

        advanceTimeBy(1)
        runCurrent()
        assertEquals(
            CarTelemetryState.Stale(connectionEpoch = 7, lastReceivedAtElapsedMs = 0),
            repo.state.value,
        )

        // A valid newer frame recovers from Stale.
        repo.submit(input(sequence = 2, connectionEpoch = 7))
        assertTrue(repo.state.value is CarTelemetryState.Current)
    }

    @Test
    fun acceptedFrameRefreshesStaleDeadline() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 1))
        advanceTimeBy(2_000)
        repo.submit(input(sequence = 2))
        advanceTimeBy(2_000)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Current)
        advanceTimeBy(1_000)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Stale)
    }

    // AA02-27: rejected frames must not keep a silent producer looking live.
    @Test
    fun rejectedFramesDoNotRefreshStaleDeadline() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 10, connectionEpoch = 2, lifecycleEpoch = 1))

        advanceTimeBy(1_000)
        repo.submit(input(sequence = 10, connectionEpoch = 2)) // duplicate
        advanceTimeBy(500)
        repo.submit(input(sequence = 11, connectionEpoch = 1)) // old epoch
        advanceTimeBy(500)
        repo.submit(input(sequence = -5, connectionEpoch = 2)) // malformed header
        advanceTimeBy(500)
        repo.submit(input(sequence = 12, connectionEpoch = 2, lifecycleEpoch = 0)) // regression
        advanceTimeBy(499)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Current)

        advanceTimeBy(1)
        runCurrent()
        assertTrue(repo.state.value is CarTelemetryState.Stale)
    }

    // AA02-28
    @Test
    fun producerReattachResetsOrderingAndState() = runTest {
        val repo = repository()
        repo.submit(input(connectionEpoch = 9, sequence = 400))

        repo.onProducerAttached()
        assertEquals(CarTelemetryState.Awaiting, repo.state.value)

        // A restarted Dart producer counts from the beginning again.
        assertEquals(
            CarTelemetrySubmitResult.ACCEPTED,
            repo.submit(input(connectionEpoch = 0, sequence = 1)),
        )
        assertEquals(0L, repo.currentFrame().connectionEpoch)
    }

    @Test
    fun reattachCancelsArmedStaleTimer() = runTest {
        val repo = repository()
        repo.submit(input(sequence = 1))
        advanceTimeBy(1_000)
        repo.onProducerAttached()
        advanceTimeBy(5_000)
        runCurrent()
        assertEquals(CarTelemetryState.Awaiting, repo.state.value)
    }

    @Test
    fun producerReattachResetsDtcRepository() = runTest {
        val dtcRepo = com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository()
        dtcRepo.submit(
            com.cbstudio.telltale.car.diagnostics.CarDtcReport(
                schemaVersion = 1,
                reportSequence = 1,
                connectionEpoch = 1,
                phase = com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase.IDLE,
                verdict = com.cbstudio.telltale.car.diagnostics.CarDtcVerdict.COMPLETE_CLEAN,
                coverageComplete = true,
                milOn = false,
                totalCodes = 0,
                freezeFrameReadIncomplete = false,
                items = emptyList(),
                freezeFrames = emptyList(),
            ),
        )
        assertTrue(dtcRepo.state.value is com.cbstudio.telltale.car.diagnostics.CarDtcState.Current)

        val repo = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
            dtcRepository = dtcRepo,
        )

        repo.onProducerAttached()
        assertEquals(com.cbstudio.telltale.car.diagnostics.CarDtcState.Awaiting, dtcRepo.state.value)
    }
}

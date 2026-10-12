package com.cbstudio.telltale.car.health

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CarAlertCoordinatorTest {

    private lateinit var testScope: TestScope
    private lateinit var telemetryRepository: CarTelemetryRepository
    private lateinit var coordinator: CarAlertCoordinator
    private var virtualTimeMs: Long = 1_000L

    @Before
    fun setUp() {
        val dispatcher = StandardTestDispatcher()
        testScope = TestScope(dispatcher)
        virtualTimeMs = 1_000L

        telemetryRepository = CarTelemetryRepository(
            scope = testScope.backgroundScope,
            elapsedRealtimeMs = { virtualTimeMs },
        )

        coordinator = CarAlertCoordinator(
            telemetryRepository = telemetryRepository,
            clock = { virtualTimeMs },
            coroutineScope = testScope.backgroundScope,
        )
    }

    private var sequenceCounter: Long = 1L

    private fun live(value: Double) = CarSignalInput(CarSignalStatus.LIVE, value)
    private fun stale() = CarSignalInput(CarSignalStatus.STALE, null)

    private fun createFrameInput(
        coolantC: CarSignalInput,
        epoch: Long = 1L,
    ) = CarTelemetryFrameInput(
        schemaVersion = 2,
        sequence = sequenceCounter++,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh = live(0.0),
        rpm = live(800.0),
        coolantC = coolantC,
        intakeAirC = live(25.0),
        controlModuleVoltageV = live(14.0),
        mapKpa = live(35.0),
        diagnosticsAvailable = true,
        milOn = false,
        dtcCount = 0,
    )

    @Test
    fun initialSnapshotIsNormal() {
        val snapshot = coordinator.repository.snapshot.value
        assertEquals(CarAlertLevel.NORMAL, snapshot.level)
        assertEquals(CarAlertPhase.NORMAL, snapshot.coolant)
    }

    @Test
    fun evaluatesCoolantAlertHysteresisAndInvokesTransitionListener() = testScope.runTest {
        val transitions = mutableListOf<CarAlertTransition>()
        val job = launch { coordinator.repository.transitions.collect { transitions.add(it) } }
        coordinator.start()
        runCurrent()

        // Normal temperature: 95°C
        telemetryRepository.submit(createFrameInput(coolantC = live(95.0)))
        runCurrent()
        assertEquals(CarAlertPhase.NORMAL, coordinator.repository.snapshot.value.coolant)
        assertEquals(0, transitions.size)

        // Overheat spike at t = 1000ms: 106°C -> enters PENDING_ENTER
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        assertEquals(CarAlertPhase.PENDING_ENTER, coordinator.repository.snapshot.value.coolant)
        assertEquals(0, transitions.size)

        // Advance 3001ms to t = 4001ms (past 3000ms hold) -> enters ACTIVE
        virtualTimeMs = 4_001L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        assertEquals(CarAlertPhase.ACTIVE, coordinator.repository.snapshot.value.coolant)
        assertEquals(CarAlertLevel.ATTENTION, coordinator.repository.snapshot.value.level)
        assertEquals(1, transitions.size)
        assertEquals(CarAlertPhase.ACTIVE, transitions[0].current.coolant)

        // Temperature cools to 98°C (< 100°C clear threshold) at t = 5000ms -> PENDING_CLEAR
        virtualTimeMs = 5_000L
        telemetryRepository.submit(createFrameInput(coolantC = live(98.0)))
        runCurrent()
        assertEquals(CarAlertPhase.PENDING_CLEAR, coordinator.repository.snapshot.value.coolant)
        assertEquals(1, transitions.size) // No new transition event yet

        // After 10,001ms hold at t = 15,001ms -> returns to NORMAL
        virtualTimeMs = 15_001L
        telemetryRepository.submit(createFrameInput(coolantC = live(98.0)))
        runCurrent()
        assertEquals(CarAlertPhase.NORMAL, coordinator.repository.snapshot.value.coolant)
        assertEquals(CarAlertLevel.NORMAL, coordinator.repository.snapshot.value.level)
        assertEquals(2, transitions.size)
        assertEquals(CarAlertPhase.NORMAL, transitions[1].current.coolant)
        job.cancel()
    }

    @Test
    fun staleSignalDuringActiveAlertTransitionsToUnknownAfterWarning() = testScope.runTest {
        val transitions = mutableListOf<CarAlertTransition>()
        val job = launch { coordinator.repository.transitions.collect { transitions.add(it) } }
        coordinator.start()
        runCurrent()

        // Trigger ACTIVE alert
        virtualTimeMs = 1_000L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        virtualTimeMs = 4_001L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        assertEquals(CarAlertPhase.ACTIVE, coordinator.repository.snapshot.value.coolant)

        // Signal becomes STALE
        virtualTimeMs = 5_000L
        telemetryRepository.submit(createFrameInput(coolantC = stale()))
        runCurrent()

        // AA05-25: Must NOT clear to NORMAL! Must transition to UNKNOWN_AFTER_WARNING
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, coordinator.repository.snapshot.value.coolant)
        assertEquals(CarAlertLevel.ATTENTION, coordinator.repository.snapshot.value.level)
        assertTrue(transitions.any { it.current.coolant == CarAlertPhase.UNKNOWN_AFTER_WARNING })
        job.cancel()
    }

    @Test
    fun connectionEpochChangeResetsAlertStateImmediately() = testScope.runTest {
        coordinator.start()
        runCurrent()

        // Trigger ACTIVE alert on epoch 1
        virtualTimeMs = 1_000L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0), epoch = 1L))
        runCurrent()
        virtualTimeMs = 4_001L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0), epoch = 1L))
        runCurrent()
        assertEquals(CarAlertPhase.ACTIVE, coordinator.repository.snapshot.value.coolant)

        // Vehicle reconnects with epoch 2 (AA05-24)
        virtualTimeMs = 5_000L
        telemetryRepository.submit(createFrameInput(coolantC = live(90.0), epoch = 2L))
        runCurrent()

        assertEquals(CarAlertPhase.NORMAL, coordinator.repository.snapshot.value.coolant)
        assertEquals(CarAlertLevel.NORMAL, coordinator.repository.snapshot.value.level)
        assertEquals(2L, coordinator.repository.snapshot.value.connectionEpoch)
    }

    @Test
    fun isSemanticAlertEdge_identifiesAllSemanticTransitions() {
        // Semantic edges into ACTIVE
        assertTrue(isSemanticAlertEdge(CarAlertPhase.NORMAL, CarAlertPhase.ACTIVE))
        assertTrue(isSemanticAlertEdge(CarAlertPhase.PENDING_ENTER, CarAlertPhase.ACTIVE))
        assertTrue(isSemanticAlertEdge(CarAlertPhase.PENDING_CLEAR, CarAlertPhase.ACTIVE))
        assertTrue(isSemanticAlertEdge(CarAlertPhase.UNKNOWN_AFTER_WARNING, CarAlertPhase.ACTIVE))

        // Semantic edges out of ACTIVE or into NORMAL
        assertTrue(isSemanticAlertEdge(CarAlertPhase.ACTIVE, CarAlertPhase.UNKNOWN_AFTER_WARNING))
        assertTrue(isSemanticAlertEdge(CarAlertPhase.ACTIVE, CarAlertPhase.NORMAL))
        assertTrue(isSemanticAlertEdge(CarAlertPhase.PENDING_CLEAR, CarAlertPhase.NORMAL))
        assertTrue(isSemanticAlertEdge(CarAlertPhase.UNKNOWN_AFTER_WARNING, CarAlertPhase.NORMAL))

        // Non-semantic internal debounce transitions
        assertFalse(isSemanticAlertEdge(CarAlertPhase.NORMAL, CarAlertPhase.NORMAL))
        assertFalse(isSemanticAlertEdge(CarAlertPhase.ACTIVE, CarAlertPhase.ACTIVE))
        assertFalse(isSemanticAlertEdge(CarAlertPhase.NORMAL, CarAlertPhase.PENDING_ENTER))
        assertFalse(isSemanticAlertEdge(CarAlertPhase.ACTIVE, CarAlertPhase.PENDING_CLEAR))
        assertFalse(isSemanticAlertEdge(CarAlertPhase.PENDING_ENTER, CarAlertPhase.NORMAL))
    }

    @Test
    fun recoveryFromUnknownAfterWarningToActiveEmitsSemanticTransition() = testScope.runTest {
        val transitions = mutableListOf<CarAlertTransition>()
        val job = launch { coordinator.repository.transitions.collect { transitions.add(it) } }
        coordinator.start()
        runCurrent()

        // 1. Enter ACTIVE alert
        virtualTimeMs = 1_000L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        virtualTimeMs = 4_001L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        assertEquals(CarAlertPhase.ACTIVE, coordinator.repository.snapshot.value.coolant)
        assertEquals(1, transitions.size)

        // 2. Drop signal -> UNKNOWN_AFTER_WARNING
        virtualTimeMs = 5_000L
        telemetryRepository.submit(createFrameInput(coolantC = stale()))
        runCurrent()
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, coordinator.repository.snapshot.value.coolant)
        assertEquals(2, transitions.size)

        // 3. Signal recovers with overheat (106°C) -> enters ACTIVE immediately
        virtualTimeMs = 6_000L
        telemetryRepository.submit(createFrameInput(coolantC = live(106.0)))
        runCurrent()
        assertEquals(CarAlertPhase.ACTIVE, coordinator.repository.snapshot.value.coolant)
        assertEquals(3, transitions.size)
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, transitions[2].previous.coolant)
        assertEquals(CarAlertPhase.ACTIVE, transitions[2].current.coolant)

        job.cancel()
    }
}

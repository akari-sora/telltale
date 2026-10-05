package com.cbstudio.telltale.car.health

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CarAlertEvaluatorTest {

    private lateinit var evaluator: CarAlertEvaluator

    @Before
    fun setUp() {
        evaluator = CarAlertEvaluator(
            policy = CarAlertPolicy(
                enterThreshold = 105.0,
                enterHoldMs = 3_000L,
                clearThreshold = 100.0,
                clearHoldMs = 10_000L,
            ),
        )
    }

    @Test
    fun startsInNormalPhaseAndNotActive() {
        assertEquals(CarAlertPhase.NORMAL, evaluator.phase)
        assertFalse(evaluator.isAlertActive)
    }

    @Test
    fun valueBelowThresholdRemainsNormal() {
        val phase = evaluator.evaluate(104.9, isLive = true, elapsedMs = 1_000L)
        assertEquals(CarAlertPhase.NORMAL, phase)
        assertFalse(evaluator.isAlertActive)
    }

    @Test
    fun spikeAboveThresholdTransitionsToPendingEnterAndRevertsIfDurationTooShort() {
        // Enters PENDING_ENTER at t = 1000ms
        evaluator.evaluate(105.0, isLive = true, elapsedMs = 1_000L)
        assertEquals(CarAlertPhase.PENDING_ENTER, evaluator.phase)
        assertFalse(evaluator.isAlertActive)

        // Drop below threshold before 3000ms hold (at t = 2000ms, elapsed 1000ms < 3000ms)
        evaluator.evaluate(104.0, isLive = true, elapsedMs = 2_000L)
        assertEquals(CarAlertPhase.NORMAL, evaluator.phase)
        assertFalse(evaluator.isAlertActive)
    }

    @Test
    fun sustainedHighValueEntersActiveAfterHoldTime() {
        // Enters PENDING_ENTER at t = 1000ms
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 1_000L)
        assertEquals(CarAlertPhase.PENDING_ENTER, evaluator.phase)

        // At t = 3999ms (elapsed 2999ms < 3000ms) still PENDING_ENTER
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 3_999L)
        assertEquals(CarAlertPhase.PENDING_ENTER, evaluator.phase)
        assertFalse(evaluator.isAlertActive)

        // At t = 4000ms (elapsed 3000ms >= 3000ms) transitions to ACTIVE
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 4_000L)
        assertEquals(CarAlertPhase.ACTIVE, evaluator.phase)
        assertTrue(evaluator.isAlertActive)
    }

    @Test
    fun clearingAlertRequiresTenSecondsBelowClearThreshold() {
        // Enter ACTIVE
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 1_000L)
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 4_000L)
        assertEquals(CarAlertPhase.ACTIVE, evaluator.phase)

        // Value drops to 100.0 at t = 5000ms -> PENDING_CLEAR
        evaluator.evaluate(100.0, isLive = true, elapsedMs = 5_000L)
        assertEquals(CarAlertPhase.PENDING_CLEAR, evaluator.phase)
        assertTrue("Alert is still active during pending clear", evaluator.isAlertActive)

        // Bounce back to 101.0 at t = 10000ms -> back to ACTIVE
        evaluator.evaluate(101.0, isLive = true, elapsedMs = 10_000L)
        assertEquals(CarAlertPhase.ACTIVE, evaluator.phase)
        assertTrue(evaluator.isAlertActive)

        // Drop again to 99.0 at t = 12000ms -> PENDING_CLEAR
        evaluator.evaluate(99.0, isLive = true, elapsedMs = 12_000L)
        assertEquals(CarAlertPhase.PENDING_CLEAR, evaluator.phase)

        // Sustained until t = 22000ms (10000ms hold) -> NORMAL
        evaluator.evaluate(99.0, isLive = true, elapsedMs = 22_000L)
        assertEquals(CarAlertPhase.NORMAL, evaluator.phase)
        assertFalse(evaluator.isAlertActive)
    }

    @Test
    fun staleSignalDuringActiveAlertPreservesWarningAsUnknownAfterWarning() {
        // Enter ACTIVE
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 1_000L)
        evaluator.evaluate(106.0, isLive = true, elapsedMs = 4_000L)
        assertEquals(CarAlertPhase.ACTIVE, evaluator.phase)

        // Signal becomes stale -> must enter UNKNOWN_AFTER_WARNING and remain active
        evaluator.evaluate(null, isLive = false, elapsedMs = 5_000L)
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, evaluator.phase)
        assertTrue("Stale signal after warning must stay active", evaluator.isAlertActive)

        // Repeated stale calls maintain UNKNOWN_AFTER_WARNING
        evaluator.evaluate(Double.NaN, isLive = true, elapsedMs = 6_000L)
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, evaluator.phase)
        assertTrue(evaluator.isAlertActive)

        // Signal resumes with hot reading -> returns to ACTIVE
        evaluator.evaluate(107.0, isLive = true, elapsedMs = 7_000L)
        assertEquals(CarAlertPhase.ACTIVE, evaluator.phase)

        // Signal becomes stale again -> UNKNOWN_AFTER_WARNING
        evaluator.evaluate(null, isLive = false, elapsedMs = 8_000L)
        assertEquals(CarAlertPhase.UNKNOWN_AFTER_WARNING, evaluator.phase)

        // Signal resumes with cooled reading -> PENDING_CLEAR (NOT directly NORMAL!)
        evaluator.evaluate(95.0, isLive = true, elapsedMs = 9_000L)
        assertEquals(CarAlertPhase.PENDING_CLEAR, evaluator.phase)
        assertTrue(evaluator.isAlertActive)

        // After 10s hold -> NORMAL
        evaluator.evaluate(95.0, isLive = true, elapsedMs = 19_000L)
        assertEquals(CarAlertPhase.NORMAL, evaluator.phase)
        assertFalse(evaluator.isAlertActive)
    }
}

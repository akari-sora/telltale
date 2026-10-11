package com.cbstudio.telltale

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ProjectionContinuityStateTest {
    @Test
    fun `paused projection can start with exact lease and registered engine`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 7)

        assertTrue(state.canStart(7, 11, activityResumed = false, hasEngine = true, projectionConnected = true))
        assertFalse(state.canStart(6, 11, activityResumed = false, hasEngine = true, projectionConnected = true))
        assertFalse(state.canStart(7, 0, activityResumed = false, hasEngine = true, projectionConnected = true))
        assertFalse(state.canStart(7, 11, activityResumed = false, hasEngine = false, projectionConnected = true))
        assertFalse(state.canStart(7, 11, activityResumed = false, hasEngine = true, projectionConnected = false))
        state.onProjectionLease(active = false, generation = 7)
        assertFalse(state.canStart(7, 11, activityResumed = false, hasEngine = true, projectionConnected = true))
    }

    @Test
    fun `paused start allowance is consumed before service result and never reopened`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 20)

        assertTrue(state.canStart(20, 31, activityResumed = false, hasEngine = true, projectionConnected = true))
        state.beginStart(projectionGeneration = 20, connectionGeneration = 31)
        state.cancelStart(projectionGeneration = 20, connectionGeneration = 31)
        assertFalse(state.canStart(20, 31, activityResumed = false, hasEngine = true, projectionConnected = true))

        state.onProjectionLease(active = true, generation = 20)
        assertFalse(state.canStart(20, 31, activityResumed = false, hasEngine = true, projectionConnected = true))
        assertTrue(state.canStart(20, 31, activityResumed = true, hasEngine = true, projectionConnected = true))

        state.beginStart(projectionGeneration = 20, connectionGeneration = 31)
        state.onProjectionLease(active = true, generation = 21)
        assertTrue(state.canStart(21, 31, activityResumed = false, hasEngine = true, projectionConnected = true))
    }

    @Test
    fun `exact release ack preserves consumed generation and newer projection gets one attempt`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 40)
        state.beginStart(projectionGeneration = 40, connectionGeneration = 51)
        assertTrue(state.markArmed(40, 51, hasEngine = true))
        assertTrue(state.serviceStopped(40, 51))
        assertTrue(state.acknowledgeRelease(40))

        state.onProjectionLease(active = true, generation = 40)
        assertFalse(state.canStart(40, 51, activityResumed = false, hasEngine = true, projectionConnected = true))
        state.onProjectionLease(active = false, generation = 40)
        state.onProjectionLease(active = true, generation = 41)
        assertTrue(state.canStart(41, 51, activityResumed = false, hasEngine = true, projectionConnected = true))
        state.beginStart(projectionGeneration = 41, connectionGeneration = 51)
        assertFalse(state.canStart(41, 51, activityResumed = false, hasEngine = true, projectionConnected = true))
    }

    @Test
    fun `exact release ack cannot tear down a reacquired generation`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 20)
        state.beginStart(projectionGeneration = 20, connectionGeneration = 31)
        assertTrue(state.markArmed(20, 31, hasEngine = true))
        state.onProjectionLease(active = false, generation = 20)
        assertTrue(state.shouldRetainEngine)

        state.onProjectionLease(active = true, generation = 21)
        assertFalse(state.acknowledgeRelease(20))
        assertFalse(state.shouldRetainEngine)
        state.beginStart(projectionGeneration = 21, connectionGeneration = 31)
        assertTrue(state.markArmed(21, 31, hasEngine = true))
        assertTrue(state.armed)
    }

    @Test
    fun `retire and service cleanup require the exact armed pair`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 5)
        state.beginStart(projectionGeneration = 5, connectionGeneration = 9)
        assertTrue(state.markArmed(5, 9, hasEngine = true))

        assertFalse(state.retire(4, 9))
        assertFalse(state.serviceStopped(5, 8))
        assertFalse(state.markArmed(4, 9, hasEngine = true))
        assertTrue(state.armed)
        assertTrue(state.serviceStopped(5, 9))
        assertFalse(state.armed)
        assertTrue(state.shouldRetainEngine)
        assertTrue(state.acknowledgeRelease(5))
        assertFalse(state.shouldRetainEngine)
    }

    @Test
    fun `release watchdog is exact and cannot clear a newer reacquire`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 30)
        state.beginStart(projectionGeneration = 30, connectionGeneration = 41)
        assertTrue(state.markArmed(30, 41, hasEngine = true))
        state.onProjectionLease(active = false, generation = 30)

        state.onProjectionLease(active = true, generation = 31)
        assertFalse(state.forceRelease(30))
        state.beginStart(projectionGeneration = 31, connectionGeneration = 41)
        assertTrue(state.markArmed(31, 41, hasEngine = true))
        assertTrue(state.armed)
    }

    @Test
    fun `release watchdog closes an unacknowledged disconnected generation`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 40)
        state.beginStart(projectionGeneration = 40, connectionGeneration = 51)
        assertTrue(state.markArmed(40, 51, hasEngine = true))
        state.onProjectionLease(active = false, generation = 40)

        assertTrue(state.shouldRetainEngine)
        assertTrue(state.forceRelease(40))
        assertFalse(state.shouldRetainEngine)
        assertFalse(state.armed)
    }

    @Test
    fun `release watchdog closes an unacknowledged service stop while projection stays active`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 60)
        state.beginStart(projectionGeneration = 60, connectionGeneration = 71)
        assertTrue(state.markArmed(60, 71, hasEngine = true))
        assertTrue(state.serviceStopped(60, 71))

        assertTrue(state.shouldRetainEngine)
        assertTrue(state.forceRelease(60))
        assertTrue(state.projectionActive)
        assertFalse(state.shouldRetainEngine)
    }

    @Test
    fun `same physical generation replay cannot defeat a service stop watchdog`() {
        val state = ProjectionContinuityState()
        state.onProjectionLease(active = true, generation = 80)
        state.beginStart(projectionGeneration = 80, connectionGeneration = 91)
        assertTrue(state.markArmed(80, 91, hasEngine = true))
        assertTrue(state.serviceStopped(80, 91))

        state.onProjectionLease(active = true, generation = 80)
        assertTrue(state.shouldRetainEngine)
        assertTrue(state.forceRelease(80))
        assertFalse(state.shouldRetainEngine)
    }
}

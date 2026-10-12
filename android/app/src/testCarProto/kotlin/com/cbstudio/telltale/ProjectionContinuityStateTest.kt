package com.cbstudio.telltale

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ProjectionContinuityStateTest {
    @Test
    fun `headless active projection retains cold start engine`() {
        val state = ProjectionContinuityState()

        state.onProjectionLease(active = true, generation = 1)
        assertTrue(state.shouldRetainEngine)

        state.onProjectionLease(active = false, generation = 1)
        assertFalse(state.shouldRetainEngine)
    }

    @Test
    fun `producer claim requires a foreground activity and registered engine`() {
        val state = ProjectionContinuityState()

        assertFalse(state.canClaimProducer(11, producerStartAuthorized = false, hasEngine = true))
        assertFalse(state.canClaimProducer(11, producerStartAuthorized = true, hasEngine = false))
        assertFalse(state.canClaimProducer(0, producerStartAuthorized = true, hasEngine = true))
        assertTrue(state.canClaimProducer(11, producerStartAuthorized = true, hasEngine = true))
    }

    @Test
    fun `pending and confirmed producer retain engine without projection`() {
        val state = ProjectionContinuityState()

        state.beginProducerClaim(11)
        assertTrue(state.shouldRetainEngine)
        assertTrue(state.confirmProducer(11, hasEngine = true))
        assertEquals(11L, state.producerConnectionGeneration)
        assertFalse(state.armed)
        assertTrue(state.shouldRetainEngine)
    }

    @Test
    fun `projection attaches only to exact confirmed producer`() {
        val state = confirmedProducer(11)
        state.onProjectionLease(active = true, generation = 7)

        assertFalse(state.canArm(7, 12, hasEngine = true, projectionConnected = true))
        assertFalse(state.canArm(7, 11, hasEngine = false, projectionConnected = true))
        assertFalse(state.canArm(7, 11, hasEngine = true, projectionConnected = false))
        assertFalse(state.canArm(6, 11, hasEngine = true, projectionConnected = true))
        assertTrue(state.canArm(7, 11, hasEngine = true, projectionConnected = true))
        assertTrue(state.markArmed(7, 11))
        assertTrue(state.armed)
    }

    @Test
    fun `projection drain acknowledgement keeps the user connected transport owner`() {
        val state = armedState(projectionGeneration = 7, connectionGeneration = 11)

        state.onProjectionLease(active = false, generation = 7)
        assertTrue("The drain watchdog needs CPU time until Dart acknowledges", state.shouldHoldWakeLock)
        assertTrue(state.acknowledgeRelease(7))

        assertFalse(state.armed)
        assertFalse(state.shouldHoldWakeLock)
        assertNull(state.connectionGeneration)
        assertEquals(11L, state.producerConnectionGeneration)
        assertTrue("Stopping car polling must not drop the connected OBD transport", state.shouldRetainEngine)
    }

    @Test
    fun `explicit projection retire and acknowledgement preserve producer`() {
        val state = armedState(projectionGeneration = 7, connectionGeneration = 11)

        assertFalse(state.retireProjection(6, 11))
        assertFalse(state.retireProjection(7, 12))
        assertTrue(state.retireProjection(7, 11))
        assertTrue(state.shouldHoldWakeLock)
        assertTrue(state.acknowledgeRelease(7))

        assertEquals(11L, state.producerConnectionGeneration)
        assertFalse(state.shouldHoldWakeLock)
        assertTrue(state.shouldRetainEngine)
    }

    @Test
    fun `unacknowledged projection drain fails closed on exact producer`() {
        val state = armedState(projectionGeneration = 40, connectionGeneration = 51)
        state.onProjectionLease(active = false, generation = 40)

        assertEquals(51L, state.forceRelease(40))
        assertNull(state.producerConnectionGeneration)
        assertFalse(state.shouldRetainEngine)
        assertFalse(state.armed)
        assertFalse(state.shouldHoldWakeLock)
    }

    @Test
    fun `stale acknowledgement and watchdog cannot affect replacement owner`() {
        val state = armedState(projectionGeneration = 20, connectionGeneration = 31)
        state.onProjectionLease(active = false, generation = 20)

        state.beginProducerClaim(32)
        assertTrue(state.confirmProducer(32, hasEngine = true))

        assertFalse(state.acknowledgeRelease(20))
        assertNull(state.forceRelease(20))
        assertEquals(32L, state.producerConnectionGeneration)
        assertTrue(state.shouldRetainEngine)
    }

    @Test
    fun `stale retire and service stop cannot affect replacement owner`() {
        val state = confirmedProducer(31)
        state.beginProducerClaim(32)
        assertTrue(state.confirmProducer(32, hasEngine = true))

        assertFalse(state.retireProducer(31))
        assertFalse(state.serviceStopped(31))
        assertEquals(32L, state.producerConnectionGeneration)
        assertTrue(state.shouldRetainEngine)
    }

    @Test
    fun `confirmed producer service loss closes armed projection`() {
        val state = armedState(projectionGeneration = 60, connectionGeneration = 71)

        assertTrue(state.serviceStopped(71))
        assertNull(state.producerConnectionGeneration)
        assertFalse(state.armed)
        assertFalse(state.shouldRetainEngine)
    }

    @Test
    fun `new projection generation clears stale attachment but keeps producer`() {
        val state = armedState(projectionGeneration = 80, connectionGeneration = 91)
        state.onProjectionLease(active = false, generation = 80)

        state.onProjectionLease(active = true, generation = 81)

        assertFalse(state.armed)
        assertNull(state.connectionGeneration)
        assertEquals(91L, state.producerConnectionGeneration)
        assertTrue("A superseding projection must not cancel the bounded drain", state.shouldHoldWakeLock)
        assertTrue(state.acknowledgeRelease(80))
        assertFalse(state.shouldHoldWakeLock)
        assertTrue(state.canArm(81, 91, hasEngine = true, projectionConnected = true))
    }

    @Test
    fun `new armed projection safely takes over wake ownership from pending drain`() {
        val state = armedState(projectionGeneration = 80, connectionGeneration = 91)
        state.onProjectionLease(active = false, generation = 80)
        state.onProjectionLease(active = true, generation = 81)

        assertTrue(state.markArmed(81, 91))

        assertNull(state.releaseAwaitingAck)
        assertTrue(state.shouldHoldWakeLock)
        assertFalse(state.acknowledgeRelease(80))
    }

    @Test
    fun `explicit producer retire is exact and clears matching projection`() {
        val state = armedState(projectionGeneration = 90, connectionGeneration = 101)

        assertFalse(state.retireProducer(100))
        assertTrue(state.armed)
        assertTrue(state.retireProducer(101))
        assertNull(state.producerConnectionGeneration)
        assertFalse(state.armed)
        assertFalse(state.shouldRetainEngine)
    }

    private fun confirmedProducer(connectionGeneration: Long): ProjectionContinuityState =
        ProjectionContinuityState().also { state ->
            state.beginProducerClaim(connectionGeneration)
            assertTrue(state.confirmProducer(connectionGeneration, hasEngine = true))
        }

    private fun armedState(
        projectionGeneration: Long,
        connectionGeneration: Long,
    ): ProjectionContinuityState =
        confirmedProducer(connectionGeneration).also { state ->
            state.onProjectionLease(active = true, generation = projectionGeneration)
            assertTrue(state.markArmed(projectionGeneration, connectionGeneration))
        }
}

package com.cbstudio.telltale.car

import androidx.car.app.connection.CarConnection
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CarProjectionSessionLeaseRuntimeTest {
    @Test
    fun `lease is identity checked idempotent and replayed`() {
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_NOT_CONNECTED,
        )
        val first = CarProjectionSessionLeaseRuntime.acquire()
        assertFalse(CarProjectionSessionLeaseRuntime.current().active)
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_PROJECTION,
        )
        assertTrue(CarProjectionSessionLeaseRuntime.current().active)
        val sibling = CarProjectionSessionLeaseRuntime.acquire()
        assertEquals(CarProjectionSessionLeaseRuntime.current().generation, sibling.generation)

        val seen = mutableListOf<CarProjectionSessionLeaseRuntime.Snapshot>()
        CarProjectionSessionLeaseRuntime.installSink { seen += it }
        assertEquals(sibling.generation, seen.single().generation)

        CarProjectionSessionLeaseRuntime.release(first)
        assertTrue(CarProjectionSessionLeaseRuntime.current().active)
        CarProjectionSessionLeaseRuntime.release(sibling)
        assertTrue(CarProjectionSessionLeaseRuntime.current().active)
        val second = CarProjectionSessionLeaseRuntime.acquire()
        assertEquals(sibling.generation, second.generation)

        CarProjectionSessionLeaseRuntime.release(first)
        assertTrue(CarProjectionSessionLeaseRuntime.current().active)
        CarProjectionSessionLeaseRuntime.release(second)
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_NOT_CONNECTED,
        )
        assertFalse(CarProjectionSessionLeaseRuntime.current().active)
        val afterDisconnect = CarProjectionSessionLeaseRuntime.acquire()
        assertFalse(CarProjectionSessionLeaseRuntime.current().active)
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_PROJECTION,
        )
        assertTrue(afterDisconnect.generation < CarProjectionSessionLeaseRuntime.current().generation)
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_NOT_CONNECTED,
        )
        CarProjectionSessionLeaseRuntime.installSink(null)
    }

    @Test
    fun `reconnect without a fresh session token stays inactive`() {
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_NOT_CONNECTED,
        )
        CarProjectionSessionLeaseRuntime.onConnectionTypeChanged(
            CarConnection.CONNECTION_TYPE_PROJECTION,
        )
        assertFalse(CarProjectionSessionLeaseRuntime.current().active)
    }
}

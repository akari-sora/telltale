package com.cbstudio.telltale.carbridge

import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarSignalValue
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import com.cbstudio.telltale.car.telemetry.CarTelemetryState
import com.cbstudio.telltale.carbridge.generated.CarTelemetryHostApi
import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * AA-02 cross-language wire contract, Kotlin half.
 *
 * Feeds the exact bytes the production Dart client sends
 * (resources/carbridge/car_telemetry_v1_frame.hex, pinned by
 * test/car/car_telemetry_wire_contract_test.dart) into the real generated
 * Pigeon handler registered exactly as FlavorPlatformRegistrar registers it,
 * and pins the reply bytes the Dart side is tested against
 * (resources/carbridge/car_telemetry_v1_reply.hex).
 *
 * The existing adapter test builds CarTelemetryMessage objects directly, so
 * it cannot see a codec, field-order or enum-ordinal disagreement between
 * the two generated halves. This test can.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class CarTelemetryWireContractTest {

    /** Captures the handler the generated setUp installs; sends nothing. */
    private class CapturingMessenger : BinaryMessenger {
        val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()
        var sends = 0

        override fun send(channel: String, message: ByteBuffer?) {
            sends++
        }

        override fun send(
            channel: String,
            message: ByteBuffer?,
            callback: BinaryMessenger.BinaryReply?,
        ) {
            sends++
        }

        override fun setMessageHandler(
            channel: String,
            handler: BinaryMessenger.BinaryMessageHandler?,
        ) {
            handlers[channel] = handler
        }
    }

    /**
     * Fixtures are test resources (src/testCarProto/resources/carbridge/), so
     * Gradle treats them as inputs: editing the bytes re-runs this test
     * instead of leaving a stale UP-TO-DATE pass.
     */
    private fun fixture(name: String): ByteArray {
        val stream =
            javaClass.getResourceAsStream("/carbridge/$name")
                ?: error("missing test resource carbridge/$name")
        val hex = stream.bufferedReader().use { it.readText() }.trim()
        require(hex.length % 2 == 0) { "odd-length hex in $name" }
        return ByteArray(hex.length / 2) { i -> hex.substring(i * 2, i * 2 + 2).toInt(16).toByte() }
    }

    private fun direct(bytes: ByteArray): ByteBuffer =
        ByteBuffer.allocateDirect(bytes.size).apply {
            put(bytes)
            rewind()
        }

    private fun ByteBuffer.toBytes(): ByteArray {
        val copy = duplicate()
        copy.rewind()
        return ByteArray(copy.remaining()).also { copy.get(it) }
    }

    private fun TestScope.repository() =
        CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { testScheduler.currentTime },
        )

    private fun CapturingMessenger.deliver(bytes: ByteArray): ByteBuffer? {
        val handler = handlers[CHANNEL]
        assertNotNull("generated setUp registered no handler on $CHANNEL", handler)
        var reply: ByteBuffer? = null
        var replied = false
        handler!!.onMessage(direct(bytes)) {
            reply = it
            replied = true
        }
        assertTrue("handler must reply synchronously", replied)
        return reply
    }

    @Test
    fun dartEncodedFrameReachesRepositoryWithEveryFieldIntact() = runTest {
        val repo = repository()
        val messenger = CapturingMessenger()
        CarTelemetryHostApi.setUp(messenger, CarTelemetryHostApiImpl(repo))

        val reply = messenger.deliver(fixture(FRAME_FIXTURE))

        val state = repo.state.value
        assertTrue("expected Current, was $state", state is CarTelemetryState.Current)
        val frame = (state as CarTelemetryState.Current).frame
        assertEquals(1L, frame.schemaVersion)
        // Above 2^32: survives only if both codecs carry 64-bit integers.
        assertEquals(5_000_000_000L, frame.sequence)
        assertEquals(7L, frame.connectionEpoch)
        assertEquals(2L, frame.lifecycleEpoch)
        assertEquals(123_456_789_012L, frame.producedAtMonotonicUs)
        assertEquals(CarConnectionPhase.CONNECTED, frame.connectionPhase)
        assertEquals(CarSignalStatus.LIVE, frame.speedKmh.status)
        assertEquals(42.5, frame.speedKmh.value!!, 0.0)
        assertEquals(CarSignalStatus.LIVE, frame.rpm.status)
        assertEquals(1800.0, frame.rpm.value!!, 0.0)
        assertEquals(CarSignalValue.STALE, frame.coolantC)
        assertEquals(CarSignalValue.UNSUPPORTED, frame.intakeAirC)
        assertEquals(CarSignalValue.UNAVAILABLE, frame.controlModuleVoltageV)
        assertEquals(CarSignalStatus.LIVE, frame.mapKpa.status)
        assertEquals(35.25, frame.mapKpa.value!!, 0.0)
        assertTrue(frame.diagnosticsAvailable)
        assertEquals(true, frame.milOn)
        assertEquals(3L, frame.dtcCount)

        // The success reply, byte for byte, that the Dart test feeds back to
        // the real Dart client.
        assertNotNull(reply)
        assertEquals(
            fixture(REPLY_FIXTURE).toHex(),
            reply!!.toBytes().toHex(),
        )
        assertEquals(listOf(null), CarTelemetryHostApi.codec.decodeMessage(direct(reply.toBytes())))
    }

    @Test
    fun theWireIsOneWayTheHostNeverSendsToDart() = runTest {
        val messenger = CapturingMessenger()
        CarTelemetryHostApi.setUp(messenger, CarTelemetryHostApiImpl(repository()))
        messenger.deliver(fixture(FRAME_FIXTURE))

        assertEquals(setOf(CHANNEL), messenger.handlers.keys)
        assertEquals("host must never call into Dart", 0, messenger.sends)
    }

    @Test
    fun replayingTheSameBytesIsADuplicateAndChangesNothing() = runTest {
        val repo = repository()
        val messenger = CapturingMessenger()
        CarTelemetryHostApi.setUp(messenger, CarTelemetryHostApiImpl(repo))

        messenger.deliver(fixture(FRAME_FIXTURE))
        val first = repo.state.value as CarTelemetryState.Current
        advanceTimeByMs(500)
        val reply = messenger.deliver(fixture(FRAME_FIXTURE))

        // Same sequence on the same epoch: dropped, receive time not refreshed,
        // but still acknowledged as a normal reply (never an error to Dart).
        assertEquals(first, repo.state.value)
        assertEquals(fixture(REPLY_FIXTURE).toHex(), reply!!.toBytes().toHex())
        assertFalse(repo.state.value is CarTelemetryState.Stale)
    }

    @Test
    fun clearingTheRegistrationRemovesTheHandler() = runTest {
        val messenger = CapturingMessenger()
        CarTelemetryHostApi.setUp(messenger, CarTelemetryHostApiImpl(repository()))
        CarTelemetryHostApi.setUp(messenger, null)
        assertNull(messenger.handlers[CHANNEL])
    }

    private fun TestScope.advanceTimeByMs(ms: Long) = testScheduler.advanceTimeBy(ms)

    private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

    private companion object {
        const val CHANNEL =
            "dev.flutter.pigeon.torque_obd.CarTelemetryHostApi.publishTelemetryFrame"
        const val FRAME_FIXTURE = "car_telemetry_v1_frame.hex"
        const val REPLY_FIXTURE = "car_telemetry_v1_reply.hex"
    }
}

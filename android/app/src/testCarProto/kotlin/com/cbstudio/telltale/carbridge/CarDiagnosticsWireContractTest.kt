package com.cbstudio.telltale.carbridge

import com.cbstudio.telltale.car.diagnostics.CarDtcCompleteness
import com.cbstudio.telltale.car.diagnostics.CarDtcKind
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.CarFreezeSignalKind
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.carbridge.generated.CarDiagnosticsHostApi
import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * AA-04 cross-language wire contract, Kotlin half.
 *
 * Feeds the exact bytes the production Dart client sends
 * (resources/carbridge/car_diagnostics_v1_report.hex, pinned by
 * test/car/car_diagnostics_wire_contract_test.dart) into the real generated
 * Pigeon handler registered exactly as FlavorPlatformRegistrar registers it,
 * and pins the reply bytes the Dart side is tested against
 * (resources/carbridge/car_diagnostics_v1_reply.hex).
 */
class CarDiagnosticsWireContractTest {

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
    fun dartEncodedReportReachesRepositoryWithEveryFieldIntact() {
        val repo = DefaultCarDtcRepository()
        val messenger = CapturingMessenger()
        CarDiagnosticsHostApi.setUp(messenger, CarDiagnosticsHostApiImpl(repo))

        val reply = messenger.deliver(fixture(REPORT_FIXTURE))

        val state = repo.state.value
        assertTrue("expected Current, was $state", state is CarDtcState.Current)
        val report = (state as CarDtcState.Current).report
        assertEquals(1L, report.schemaVersion)
        // Above 2^32: survives only if both codecs carry 64-bit integers.
        assertEquals(5_000_000_000L, report.reportSequence)
        assertEquals(7L, report.connectionEpoch)
        assertEquals(CarDtcScanPhase.IDLE, report.phase)
        assertEquals(CarDtcVerdict.FAULTS_FOUND, report.verdict)
        assertTrue(report.coverageComplete)
        assertEquals(true, report.milOn)
        assertEquals(3L, report.totalCodes)
        assertEquals(false, report.freezeFrameReadIncomplete)

        assertEquals(3, report.items.size)
        val item0 = report.items[0]
        assertEquals("P0300", item0.code)
        assertEquals(CarDtcKind.STORED, item0.kind)
        assertEquals("7E8", item0.sourceId)
        assertEquals(false, item0.isManufacturerSpecific)
        assertEquals(CarDtcCompleteness.COMPLETE, item0.completeness)

        val item1 = report.items[1]
        assertEquals("P0171", item1.code)
        assertEquals(CarDtcKind.PENDING, item1.kind)
        assertNull(item1.sourceId)
        assertEquals(false, item1.isManufacturerSpecific)
        assertEquals(CarDtcCompleteness.PARTIAL, item1.completeness)

        val item2 = report.items[2]
        assertEquals("C0035", item2.code)
        assertEquals(CarDtcKind.PERMANENT, item2.kind)
        assertEquals("7E0", item2.sourceId)
        assertEquals(true, item2.isManufacturerSpecific)
        assertEquals(CarDtcCompleteness.COMPLETE, item2.completeness)

        assertEquals(1, report.freezeFrames.size)
        val ff = report.freezeFrames[0]
        assertEquals("7E8", ff.sourceId)
        assertEquals(0, ff.frameNumber)
        assertEquals("P0300", ff.causeCode)
        assertEquals(CarDtcKind.STORED, ff.causeKind)
        assertEquals("7E8", ff.causeSourceId)
        assertEquals(7, ff.readings.size)
        assertEquals(CarFreezeSignalKind.SPEED_KMH, ff.readings[0].signal)
        assertEquals(65.0, ff.readings[0].value, 0.0)
        assertEquals(CarFreezeSignalKind.RPM, ff.readings[1].signal)
        assertEquals(2200.0, ff.readings[1].value, 0.0)
        assertEquals(CarFreezeSignalKind.COOLANT_C, ff.readings[2].signal)
        assertEquals(98.0, ff.readings[2].value, 0.0)
        assertEquals(CarFreezeSignalKind.INTAKE_AIR_C, ff.readings[3].signal)
        assertEquals(30.0, ff.readings[3].value, 0.0)
        assertEquals(CarFreezeSignalKind.ENGINE_LOAD_PCT, ff.readings[4].signal)
        assertEquals(45.0, ff.readings[4].value, 0.0)
        assertEquals(CarFreezeSignalKind.MAP_KPA, ff.readings[5].signal)
        assertEquals(70.0, ff.readings[5].value, 0.0)
        assertEquals(CarFreezeSignalKind.CONTROL_MODULE_VOLTAGE_V, ff.readings[6].signal)
        assertEquals(13.8, ff.readings[6].value, 0.0)
        assertEquals(1, ff.undecodableCount)
        assertEquals(2, ff.unreadCount)
        assertEquals(3, ff.omittedByProjectionCount)
        assertEquals(false, ff.contentsUnknown)

        assertNotNull(reply)
        assertEquals(
            fixture(REPLY_FIXTURE).toHex(),
            reply!!.toBytes().toHex(),
        )
        assertEquals(listOf(null), CarDiagnosticsHostApi.codec.decodeMessage(direct(reply.toBytes())))
    }

    @Test
    fun theWireIsOneWayTheHostNeverSendsToDart() {
        val messenger = CapturingMessenger()
        CarDiagnosticsHostApi.setUp(messenger, CarDiagnosticsHostApiImpl(DefaultCarDtcRepository()))
        messenger.deliver(fixture(REPORT_FIXTURE))

        assertEquals(setOf(CHANNEL), messenger.handlers.keys)
        assertEquals("host must never call into Dart", 0, messenger.sends)
    }

    @Test
    fun replayingTheSameBytesIsADuplicateAndChangesNothing() {
        val repo = DefaultCarDtcRepository()
        val messenger = CapturingMessenger()
        CarDiagnosticsHostApi.setUp(messenger, CarDiagnosticsHostApiImpl(repo))

        messenger.deliver(fixture(REPORT_FIXTURE))
        val first = repo.state.value as CarDtcState.Current
        val reply = messenger.deliver(fixture(REPORT_FIXTURE))

        // Same sequence on the same epoch: dropped, but still acknowledged as normal reply
        assertEquals(first, repo.state.value)
        assertEquals(fixture(REPLY_FIXTURE).toHex(), reply!!.toBytes().toHex())
    }

    @Test
    fun clearingTheRegistrationRemovesTheHandler() {
        val messenger = CapturingMessenger()
        CarDiagnosticsHostApi.setUp(messenger, CarDiagnosticsHostApiImpl(DefaultCarDtcRepository()))
        CarDiagnosticsHostApi.setUp(messenger, null)
        assertNull(messenger.handlers[CHANNEL])
    }

    private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

    private companion object {
        const val CHANNEL =
            "dev.flutter.pigeon.torque_obd.CarDiagnosticsHostApi.publishDtcReport"
        const val REPORT_FIXTURE = "car_diagnostics_v1_report.hex"
        const val REPLY_FIXTURE = "car_diagnostics_v1_reply.hex"
    }
}

package com.cbstudio.telltale.car.hardware

import androidx.car.app.HandshakeInfo
import androidx.car.app.hardware.CarHardwareManager
import androidx.car.app.hardware.common.CarValue
import androidx.car.app.hardware.common.OnCarDataAvailableListener
import androidx.car.app.hardware.info.CarInfo
import androidx.car.app.hardware.info.EnergyLevel
import androidx.car.app.hardware.info.EnergyProfile
import androidx.car.app.hardware.info.EvStatus
import androidx.car.app.hardware.info.Mileage
import androidx.car.app.hardware.info.Model
import androidx.car.app.hardware.info.Speed
import androidx.car.app.hardware.info.TollCard
import androidx.car.app.testing.TestCarContext
import androidx.car.app.versioning.CarAppApiLevels
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.concurrent.Executor

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AndroidCarHardwareSpeedGatewayTest {

    private lateinit var carContext: TestCarContext
    private lateinit var fakeCarInfo: FakeCarInfo
    private var virtualTimeMs = 1_000L

    @Before
    fun setUp() {
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext(),
        )
        fakeCarInfo = FakeCarInfo()
    }

    private fun configureCarApiLevel(level: Int = CarAppApiLevels.LEVEL_3) {
        carContext.updateHandshakeInfo(
            HandshakeInfo("com.google.android.projection.gearhead", level),
        )
        carContext.overrideCarService(
            CarHardwareManager::class.java,
            FakeCarHardwareManager(fakeCarInfo),
        )
    }

    private fun createSpeed(rawMps: Float, dispMps: Float): Speed {
        return Speed.Builder()
            .setRawSpeedMetersPerSecond(CarValue(rawMps, 100L, CarValue.STATUS_SUCCESS))
            .setDisplaySpeedMetersPerSecond(CarValue(dispMps, 100L, CarValue.STATUS_SUCCESS))
            .build()
    }

    @Test
    fun startListening_whenApiLevelBelow3_emitsUnimplemented() {
        var sample: CarHostSpeedSample? = null
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        gateway.startListening { sample = it }

        assertEquals(CarHostSpeedStatus.UNIMPLEMENTED, sample?.status)
        assertEquals(virtualTimeMs, sample?.receivedAtElapsedMs)
    }

    @Test
    fun startListening_withApiLevel3_registersListenerAndDeliversLiveSample() {
        configureCarApiLevel(CarAppApiLevels.LEVEL_3)
        var receivedSample: CarHostSpeedSample? = null
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        gateway.startListening { receivedSample = it }

        assertEquals(1, fakeCarInfo.registeredListeners.size)
        val listener = fakeCarInfo.registeredListeners[0]

        listener.onCarDataAvailable(createSpeed(25f, 25f))

        assertNotNull(receivedSample)
        assertEquals(CarHostSpeedStatus.LIVE, receivedSample?.status)
        assertEquals(25f, receivedSample?.displaySpeedMetersPerSecond)
    }

    @Test
    fun queuedCallbackFromPreviousRegistration_afterStopAndStart_isRejectedByGateway() {
        configureCarApiLevel(CarAppApiLevels.LEVEL_3)
        val receivedSamples = mutableListOf<CarHostSpeedSample>()
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        // 1. Start generation A
        gateway.startListening { receivedSamples.add(it) }
        assertEquals(1, fakeCarInfo.registeredListeners.size)
        val listenerA = fakeCarInfo.registeredListeners[0]

        // 2. Stop and start generation B
        gateway.stopListening()
        gateway.startListening { receivedSamples.add(it) }
        assertEquals(2, fakeCarInfo.registeredListeners.size)
        val listenerB = fakeCarInfo.registeredListeners[1]

        // 3. Listener B delivers fresh sample
        listenerB.onCarDataAvailable(createSpeed(30f, 30f))
        assertEquals(1, receivedSamples.size)
        assertEquals(30f, receivedSamples.last().displaySpeedMetersPerSecond)

        // 4. Stale callback from generation A executes late
        listenerA.onCarDataAvailable(createSpeed(0f, 0f))

        // Direct consumer must NOT receive sample from listener A!
        assertEquals(1, receivedSamples.size)
        assertEquals(30f, receivedSamples.last().displaySpeedMetersPerSecond)
    }

    @Test
    fun queuedCallbackFromPreviousRegistration_afterDirectReStart_isRejectedByGateway() {
        configureCarApiLevel(CarAppApiLevels.LEVEL_3)
        val receivedSamples = mutableListOf<CarHostSpeedSample>()
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        // 1. Start generation A
        gateway.startListening { receivedSamples.add(it) }
        assertEquals(1, fakeCarInfo.registeredListeners.size)
        val listenerA = fakeCarInfo.registeredListeners[0]

        // 2. Direct re-start without explicit stopListening() call
        gateway.startListening { receivedSamples.add(it) }
        assertEquals(2, fakeCarInfo.registeredListeners.size)
        val listenerB = fakeCarInfo.registeredListeners[1]

        // 3. Listener B delivers fresh sample
        listenerB.onCarDataAvailable(createSpeed(35f, 35f))
        assertEquals(1, receivedSamples.size)
        assertEquals(35f, receivedSamples.last().displaySpeedMetersPerSecond)

        // 4. Stale callback from generation A executes late
        listenerA.onCarDataAvailable(createSpeed(10f, 10f))

        // Must remain unaffected by listener A
        assertEquals(1, receivedSamples.size)
        assertEquals(35f, receivedSamples.last().displaySpeedMetersPerSecond)
    }

    @Test
    fun stopListening_afterActiveRegistration_unregistersProperListenerIdentityAndIsIdempotent() {
        configureCarApiLevel(CarAppApiLevels.LEVEL_3)
        val receivedSamples = mutableListOf<CarHostSpeedSample>()
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        gateway.startListening { receivedSamples.add(it) }
        assertEquals(1, fakeCarInfo.registeredListeners.size)
        val registeredListener = fakeCarInfo.registeredListeners[0]

        // 1. First stopListening unregisters listener from carInfo
        gateway.stopListening()
        assertEquals(1, fakeCarInfo.removedListeners.size)
        assertEquals(registeredListener, fakeCarInfo.removedListeners[0])

        // 2. Subsequent stopListening does not call carInfo.removeSpeedListener again
        gateway.stopListening()
        assertEquals(1, fakeCarInfo.removedListeners.size)

        // 3. Late callback after stop does not reach consumer
        registeredListener.onCarDataAvailable(createSpeed(20f, 20f))
        assertTrue(receivedSamples.isEmpty())
    }

    @Test
    fun stopListening_whenCarInfoThrowsException_swallowsErrorAndInvalidatesRegistration() {
        configureCarApiLevel(CarAppApiLevels.LEVEL_3)
        val receivedSamples = mutableListOf<CarHostSpeedSample>()
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        gateway.startListening { receivedSamples.add(it) }
        val registeredListener = fakeCarInfo.registeredListeners[0]

        // Simulate underlying unregister exception
        fakeCarInfo.removeThrowsException = true
        gateway.stopListening() // Must not throw exception

        // Stale callback executed after exception must be discarded
        registeredListener.onCarDataAvailable(createSpeed(20f, 20f))
        assertTrue(receivedSamples.isEmpty())

        // Multiple stops remain safe
        gateway.stopListening()
    }

    @Test
    fun stopListening_synchronousReentrantCallbackDuringUnregister_isRejected() {
        configureCarApiLevel(CarAppApiLevels.LEVEL_3)
        val receivedSamples = mutableListOf<CarHostSpeedSample>()
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )

        gateway.startListening { receivedSamples.add(it) }
        val registeredListener = fakeCarInfo.registeredListeners[0]

        // Simulate reentrant callback during removeSpeedListener invocation
        fakeCarInfo.onRemoveListenerAction = {
            registeredListener.onCarDataAvailable(createSpeed(15f, 15f))
        }

        gateway.stopListening()

        // Because speedListener and activeRegistrationToken were cleared BEFORE removeSpeedListener,
        // the reentrant callback must be rejected!
        assertTrue(receivedSamples.isEmpty())
    }

    @Test
    fun parseSpeed_withSuccessFiniteFloats_returnsLiveSample() {
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )
        val speed = Speed.Builder()
            .setRawSpeedMetersPerSecond(CarValue(25.5f, 100L, CarValue.STATUS_SUCCESS))
            .setDisplaySpeedMetersPerSecond(CarValue(26.0f, 100L, CarValue.STATUS_SUCCESS))
            .build()

        val sample = gateway.parseSpeed(speed, virtualTimeMs)
        assertEquals(CarHostSpeedStatus.LIVE, sample.status)
        assertEquals(25.5f, sample.rawMetersPerSecond)
        assertEquals(26.0f, sample.displaySpeedMetersPerSecond)
        assertEquals(virtualTimeMs, sample.receivedAtElapsedMs)
    }

    @Test
    fun parseSpeed_withUnavailableOrError_returnsNullValues() {
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )
        val speed = Speed.Builder()
            .setRawSpeedMetersPerSecond(CarValue(0f, 100L, CarValue.STATUS_UNAVAILABLE))
            .setDisplaySpeedMetersPerSecond(CarValue(0f, 100L, CarValue.STATUS_UNAVAILABLE))
            .build()

        val sample = gateway.parseSpeed(speed, virtualTimeMs)
        assertEquals(CarHostSpeedStatus.UNAVAILABLE, sample.status)
        assertNull(sample.rawMetersPerSecond)
        assertNull(sample.displaySpeedMetersPerSecond)
    }

    @Test
    fun parseSpeed_withNonFiniteFloats_failsClosedToUnavailable() {
        val gateway = AndroidCarHardwareSpeedGateway(
            carContext = carContext,
            clock = { virtualTimeMs },
        )
        val speed = Speed.Builder()
            .setRawSpeedMetersPerSecond(CarValue(Float.NaN, 100L, CarValue.STATUS_SUCCESS))
            .setDisplaySpeedMetersPerSecond(CarValue(Float.POSITIVE_INFINITY, 100L, CarValue.STATUS_SUCCESS))
            .build()

        val sample = gateway.parseSpeed(speed, virtualTimeMs)
        assertEquals(CarHostSpeedStatus.UNAVAILABLE, sample.status)
        assertNull(sample.rawMetersPerSecond)
        assertNull(sample.displaySpeedMetersPerSecond)
    }

    private class FakeCarHardwareManager(private val carInfo: CarInfo) : CarHardwareManager {
        override fun getCarInfo(): CarInfo = carInfo
    }

    private class FakeCarInfo : CarInfo {
        val registeredListeners = mutableListOf<OnCarDataAvailableListener<Speed>>()
        val removedListeners = mutableListOf<OnCarDataAvailableListener<Speed>>()
        var removeThrowsException = false
        var onRemoveListenerAction: (() -> Unit)? = null

        override fun addSpeedListener(
            executor: Executor,
            listener: OnCarDataAvailableListener<Speed>,
        ) {
            registeredListeners.add(listener)
        }

        override fun removeSpeedListener(listener: OnCarDataAvailableListener<Speed>) {
            onRemoveListenerAction?.invoke()
            if (removeThrowsException) {
                throw RuntimeException("Simulated unregister failure")
            }
            removedListeners.add(listener)
        }

        override fun fetchModel(executor: Executor, listener: OnCarDataAvailableListener<Model>) {}
        override fun fetchEnergyProfile(executor: Executor, listener: OnCarDataAvailableListener<EnergyProfile>) {}
        override fun addTollListener(executor: Executor, listener: OnCarDataAvailableListener<TollCard>) {}
        override fun removeTollListener(listener: OnCarDataAvailableListener<TollCard>) {}
        override fun addEnergyLevelListener(executor: Executor, listener: OnCarDataAvailableListener<EnergyLevel>) {}
        override fun removeEnergyLevelListener(listener: OnCarDataAvailableListener<EnergyLevel>) {}
        override fun addMileageListener(executor: Executor, listener: OnCarDataAvailableListener<Mileage>) {}
        override fun removeMileageListener(listener: OnCarDataAvailableListener<Mileage>) {}
        override fun addEvStatusListener(executor: Executor, listener: OnCarDataAvailableListener<EvStatus>) {}
        override fun removeEvStatusListener(listener: OnCarDataAvailableListener<EvStatus>) {}
    }
}

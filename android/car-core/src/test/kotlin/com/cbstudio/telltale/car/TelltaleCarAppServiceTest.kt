package com.cbstudio.telltale.car

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.testing.SessionController
import androidx.car.app.testing.TestCarContext
import androidx.car.app.validation.HostValidator
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.cbstudio.telltale.car.diagnostics.CarDtcReport
import com.cbstudio.telltale.car.diagnostics.CarDtcScanPhase
import com.cbstudio.telltale.car.diagnostics.CarDtcState
import com.cbstudio.telltale.car.diagnostics.CarDtcVerdict
import com.cbstudio.telltale.car.diagnostics.DefaultCarDtcRepository
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample
import com.cbstudio.telltale.car.telemetry.CarConnectionPhase
import com.cbstudio.telltale.car.telemetry.CarSignalInput
import com.cbstudio.telltale.car.telemetry.CarSignalStatus
import com.cbstudio.telltale.car.telemetry.CarTelemetryFrameInput
import com.cbstudio.telltale.car.telemetry.CarTelemetryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class TelltaleCarAppServiceTest {

    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        carContext =
            TestCarContext.createCarContext(
                ApplicationProvider.getApplicationContext(),
            )
    }

    @Test
    fun onCreateSession_returnsTelltaleCarSession() {
        val service = Robolectric.buildService(TelltaleCarAppService::class.java).create().get()
        val session = service.onCreateSession()

        assertNotNull(session)
        assertTrue(session is TelltaleCarSession)
    }

    @Test
    fun session_onCreateScreen_returnsCarHomeScreen() {
        val session = TelltaleCarSession()
        val intent = Intent()
        val controller = SessionController(session, carContext, intent)

        controller.moveToState(Lifecycle.State.CREATED)

        val screen = session.onCreateScreen(Intent())
        assertNotNull(screen)
        assertTrue(screen is CarHomeScreen)
    }

    @Test
    fun session_onCreateScreen_startsRuntimeIfLifecycleAlreadyStarted() {
        var startCount = 0
        val countingGateway = object : CarHardwareSpeedGateway {
            override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) {
                startCount++
            }
            override fun stopListening() {}
        }
        val session = TelltaleCarSession { s ->
            CarSessionRuntime(
                carContext = s.carContext,
                hostSpeedGateway = countingGateway,
            )
        }
        val intent = Intent()
        val controller = SessionController(session, carContext, intent)

        // Move session to STARTED
        controller.moveToState(Lifecycle.State.STARTED)
        val runtime = session.sessionRuntime
        assertTrue(runtime.isStarted)
        assertEquals(1, startCount)

        // Explicitly simulate stopped runtime while session lifecycle remains STARTED
        runtime.stop()
        assertEquals(Lifecycle.State.STARTED, session.lifecycle.currentState)
        assertFalse(runtime.isStarted)

        // Now calling onCreateScreen tests the recovery branch:
        val screen = session.onCreateScreen(Intent())
        assertNotNull(screen)
        assertTrue(screen is CarHomeScreen)
        assertTrue(runtime.isStarted)
        assertEquals(2, startCount)

        // Subsequent onCreateScreen call does not duplicate start
        session.onCreateScreen(Intent())
        assertEquals(2, startCount)

        runtime.destroy()
    }

    @Test
    fun session_onCreateScreen_returnsHomeScreen() {
        val session = TelltaleCarSession()
        val controller = SessionController(session, carContext, Intent())
        controller.moveToState(Lifecycle.State.CREATED)

        val screen = session.onCreateScreen(Intent())
        assertTrue(screen is CarHomeScreen)
    }

    @Test
    fun session_recreationReplaysSameEpochDtcWhileEpochAndProducerChangesInvalidateIt() = runTest {
        val dtcRepository = DefaultCarDtcRepository()
        val telemetryRepository = CarTelemetryRepository(
            scope = backgroundScope,
            elapsedRealtimeMs = { 1_000L },
            dtcRepository = dtcRepository,
        )
        val originalReport = dtcReport(sequence = 1, epoch = 7)
        telemetryRepository.submit(telemetryFrame(sequence = 1, epoch = 7))
        dtcRepository.submit(originalReport)

        fun newSession(): TelltaleCarSession = TelltaleCarSession { session ->
            CarSessionRuntime(
                carContext = session.carContext,
                telemetryRepository = telemetryRepository,
                dtcRepository = dtcRepository,
                hostSpeedGateway = NoOpCarHardwareSpeedGateway,
                coroutineScope = backgroundScope,
            )
        }

        val firstSession = newSession()
        val firstController = SessionController(firstSession, carContext, Intent())
        firstController.moveToState(Lifecycle.State.STARTED)
        assertTrue(dtcRepository.state.value is CarDtcState.Current)

        firstController.moveToState(Lifecycle.State.DESTROYED)
        assertEquals(CarDtcState.Awaiting, dtcRepository.state.value)
        assertEquals(originalReport, dtcRepository.latestValidReport)

        val replacementSession = newSession()
        val replacementController = SessionController(replacementSession, carContext, Intent())
        replacementController.moveToState(Lifecycle.State.STARTED)
        val replayed = dtcRepository.state.value
        assertTrue("Expected cached report to replay in replacement session, was $replayed", replayed is CarDtcState.Current)
        assertEquals(originalReport, (replayed as CarDtcState.Current).report)

        replacementController.moveToState(Lifecycle.State.DESTROYED)
        telemetryRepository.submit(telemetryFrame(sequence = 1, epoch = 8))
        assertEquals(CarDtcState.Awaiting, dtcRepository.state.value)
        assertEquals(null, dtcRepository.latestValidReport)

        dtcRepository.submit(dtcReport(sequence = 1, epoch = 8))
        assertTrue(dtcRepository.state.value is CarDtcState.Current)
        telemetryRepository.onProducerAttached()
        assertEquals(CarDtcState.Awaiting, dtcRepository.state.value)
        assertEquals(null, dtcRepository.latestValidReport)
    }

    @Test
    fun createHostValidator_whenDebuggable_returnsAllowAll() {
        val service = Robolectric.buildService(TelltaleCarAppService::class.java).create().get()
        service.applicationInfo.flags = service.applicationInfo.flags or ApplicationInfo.FLAG_DEBUGGABLE

        val validator = service.createHostValidator()
        assertEquals(HostValidator.ALLOW_ALL_HOSTS_VALIDATOR, validator)
    }

    @Test
    fun createHostValidator_whenNonDebuggable_returnsSampleAllowlistValidator() {
        val service = Robolectric.buildService(TelltaleCarAppService::class.java).create().get()
        service.applicationInfo.flags = service.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE.inv()

        val validator = service.createHostValidator()
        assertNotNull(validator)
        // Ensure it is not the allow-all validator when non-debuggable
        assertTrue(validator != HostValidator.ALLOW_ALL_HOSTS_VALIDATOR)
    }

    private fun dtcReport(sequence: Long, epoch: Long) = CarDtcReport(
        schemaVersion = CarDtcReport.SCHEMA_VERSION,
        reportSequence = sequence,
        connectionEpoch = epoch,
        phase = CarDtcScanPhase.IDLE,
        verdict = CarDtcVerdict.COMPLETE_CLEAN,
        coverageComplete = true,
        milOn = false,
        totalCodes = 0,
        freezeFrameReadIncomplete = false,
        items = emptyList(),
        freezeFrames = emptyList(),
    )

    private fun telemetryFrame(sequence: Long, epoch: Long) = CarTelemetryFrameInput(
        schemaVersion = 2,
        sequence = sequence,
        connectionEpoch = epoch,
        lifecycleEpoch = 0,
        producedAtMonotonicUs = 1_000,
        connectionPhase = CarConnectionPhase.CONNECTED,
        speedKmh = CarSignalInput(CarSignalStatus.LIVE, 0.0),
        rpm = CarSignalInput(CarSignalStatus.LIVE, 800.0),
        coolantC = CarSignalInput(CarSignalStatus.LIVE, 90.0),
        intakeAirC = CarSignalInput(CarSignalStatus.LIVE, 25.0),
        controlModuleVoltageV = CarSignalInput(CarSignalStatus.LIVE, 14.0),
        mapKpa = CarSignalInput(CarSignalStatus.LIVE, 35.0),
        diagnosticsAvailable = true,
        milOn = false,
        dtcCount = 0,
    )

    private object NoOpCarHardwareSpeedGateway : CarHardwareSpeedGateway {
        override fun startListening(onSpeedAvailable: (CarHostSpeedSample) -> Unit) = Unit
        override fun stopListening() = Unit
    }
}

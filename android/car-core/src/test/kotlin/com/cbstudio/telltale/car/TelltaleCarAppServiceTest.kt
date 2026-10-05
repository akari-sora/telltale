package com.cbstudio.telltale.car

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.testing.SessionController
import androidx.car.app.testing.TestCarContext
import androidx.car.app.validation.HostValidator
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
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
import com.cbstudio.telltale.car.hardware.CarHardwareSpeedGateway
import com.cbstudio.telltale.car.hardware.CarHostSpeedSample

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
}

package com.cbstudio.telltale.car

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.testing.SessionController
import androidx.car.app.testing.TestCarContext
import androidx.car.app.validation.HostValidator
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

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

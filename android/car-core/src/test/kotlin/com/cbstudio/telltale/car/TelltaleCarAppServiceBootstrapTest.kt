package com.cbstudio.telltale.car

import android.app.Application
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = CountingCarBootstrapApplication::class)
class TelltaleCarAppServiceBootstrapTest {
    @Before
    fun resetCounts() {
        CountingCarBootstrapApplication.starts = 0
        CountingCarBootstrapApplication.stops = 0
    }

    @Test
    fun `cold service starts application runtime and releases it on destroy`() {
        val controller = Robolectric.buildService(TelltaleCarAppService::class.java)

        controller.create()
        assertEquals(1, CountingCarBootstrapApplication.starts)
        assertEquals(0, CountingCarBootstrapApplication.stops)

        controller.destroy()
        assertEquals(1, CountingCarBootstrapApplication.starts)
        assertEquals(1, CountingCarBootstrapApplication.stops)
    }
}

class CountingCarBootstrapApplication : Application(), CarProcessBootstrap {
    override fun ensureCarRuntimeStarted() {
        starts++
    }

    override fun releaseCarRuntimeIfIdle() {
        stops++
    }

    companion object {
        var starts = 0
        var stops = 0
    }
}

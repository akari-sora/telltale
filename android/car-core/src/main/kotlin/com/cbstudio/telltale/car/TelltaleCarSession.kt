package com.cbstudio.telltale.car

import android.content.Intent
import android.content.res.Configuration
import androidx.car.app.Screen
import androidx.car.app.ScreenManager
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner



/**
 * Android for Cars session managing session-scoped runtime and initial screen creation (AA-05).
 */
class TelltaleCarSession(
    internal var runtimeProvider: ((TelltaleCarSession) -> CarSessionRuntime)? = null,
) : Session(), DefaultLifecycleObserver {

    private var projectionLease: CarProjectionSessionLeaseRuntime.Token? = null
    private var renderedAppearance: Pair<Boolean, Int>? = null
    internal var invalidateTopScreen: () -> Unit = {
        carContext.getCarService(ScreenManager::class.java).top.invalidate()
    }

    lateinit var sessionRuntime: CarSessionRuntime
        internal set

    init {
        lifecycle.addObserver(this)
    }

    override fun onCreateScreen(intent: Intent): Screen {
        if (projectionLease == null) {
            projectionLease = CarProjectionSessionLeaseRuntime.acquire()
        }
        if (!::sessionRuntime.isInitialized) {
            sessionRuntime = runtimeProvider?.invoke(this) ?: CarSessionRuntime(carContext)
        }
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED) && !sessionRuntime.isStarted) {
            sessionRuntime.start()
        }
        renderedAppearance = appearance()
        return CarHomeScreen(carContext = carContext, sessionRuntime = sessionRuntime, graphicalDashboard = true)
    }

    /**
     * The library updates CarContext resources on a host configuration change but does not ask for
     * a new template. Grid gauge bitmaps depend on day/night mode and density, so re-render the top
     * screen once when either changes. Same template, titles and item count: a refresh, not a step.
     */
    override fun onCarConfigurationChanged(newConfiguration: Configuration) {
        val current = appearance()
        if (current == renderedAppearance) return
        renderedAppearance = current
        try {
            invalidateTopScreen()
        } catch (_: RuntimeException) {
            // No screen yet, or the host is not accepting invalidations; the next template uses it.
        }
    }

    private fun appearance(): Pair<Boolean, Int> =
        carContext.isDarkMode to carContext.resources.configuration.densityDpi

    override fun onStart(owner: LifecycleOwner) {
        if (::sessionRuntime.isInitialized) {
            sessionRuntime.start()
        }
    }

    override fun onStop(owner: LifecycleOwner) {
        if (::sessionRuntime.isInitialized) {
            sessionRuntime.stop()
        }
    }

    override fun onDestroy(owner: LifecycleOwner) {
        if (::sessionRuntime.isInitialized) {
            sessionRuntime.destroy(clearDiagnosticsSnapshot = false)
        }
        projectionLease?.let(CarProjectionSessionLeaseRuntime::release)
        projectionLease = null
        // A projected Session is routinely destroyed while the user switches
        // to Maps or the Android Auto home screen. The process-scoped lease is
        // retired only by the actual CarConnection NOT_CONNECTED signal.
    }
}

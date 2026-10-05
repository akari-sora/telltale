package com.cbstudio.telltale.car

import android.content.Intent
import androidx.car.app.Screen
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

    lateinit var sessionRuntime: CarSessionRuntime
        internal set

    init {
        lifecycle.addObserver(this)
    }

    override fun onCreateScreen(intent: Intent): Screen {
        if (!::sessionRuntime.isInitialized) {
            sessionRuntime = runtimeProvider?.invoke(this) ?: CarSessionRuntime(carContext)
        }
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED) && !sessionRuntime.isStarted) {
            sessionRuntime.start()
        }
        return CarHomeScreen(carContext = carContext, sessionRuntime = sessionRuntime)
    }

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
            sessionRuntime.destroy()
        }
    }
}

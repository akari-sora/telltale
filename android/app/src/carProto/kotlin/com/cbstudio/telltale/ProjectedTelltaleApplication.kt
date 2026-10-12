package com.cbstudio.telltale

import android.app.Application
import com.cbstudio.telltale.car.CarProcessBootstrap

/** Application hook shared by the production field and carProto projections. */
class ProjectedTelltaleApplication : Application(), CarProcessBootstrap {
    override fun ensureCarRuntimeStarted() {
        ProjectionContinuityRuntime.onCarServiceStarted(this)
    }

    override fun releaseCarRuntimeIfIdle() {
        ProjectionContinuityRuntime.onCarServiceStopped()
    }
}

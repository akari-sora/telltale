package com.cbstudio.telltale.car.telemetry

import android.os.SystemClock
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

/**
 * Process-wide holder of the car telemetry repository.
 *
 * In the projected (carProto) app the Flutter producer and the CarAppService
 * share one process, so one repository instance is the meeting point. This is
 * not a runtime owner: it starts nothing, holds no WakeLock and keeps no
 * FlutterEngine alive. When the Flutter side stops producing, the repository
 * simply goes stale.
 */
object CarTelemetryRuntime {
    val repository: CarTelemetryRepository by lazy {
        CarTelemetryRepository(
            scope = CoroutineScope(SupervisorJob() + Dispatchers.Default),
            elapsedRealtimeMs = SystemClock::elapsedRealtime,
        )
    }
}

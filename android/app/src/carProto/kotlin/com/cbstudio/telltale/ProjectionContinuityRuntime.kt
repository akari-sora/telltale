package com.cbstudio.telltale

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.cbstudio.telltale.car.CarProjectionSessionLeaseRuntime
import com.cbstudio.telltale.carbridge.generated.session.CarProjectionLeaseMessage
import com.cbstudio.telltale.carbridge.generated.session.CarProjectionSessionFlutterApi
import com.cbstudio.telltale.carbridge.generated.session.CarProjectionSessionHostApi
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference

internal object ProjectionContinuityRuntime : CarProjectionSessionHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var applicationContext: Context? = null
    private var engine: FlutterEngine? = null
    private var activity: WeakReference<MainActivity>? = null
    private var activityResumed = false
    private val state = ProjectionContinuityState()
    private var releaseWatchdogGeneration: Long? = null
    private var releaseWatchdog: Runnable? = null

    @Synchronized
    fun registerEngine(next: FlutterEngine) {
        if (engine === next) return
        engine = next
        CarProjectionSessionHostApi.setUp(next.dartExecutor.binaryMessenger, this)
        publishLocked()
    }

    @Synchronized
    fun onActivityResumed(next: MainActivity) {
        applicationContext = next.applicationContext
        CarProjectionSessionLeaseRuntime.installProjectionConnectionGuard(next.applicationContext)
        activity = WeakReference(next)
        activityResumed = true
        publishLocked()
    }

    @Synchronized
    fun onActivityPaused(candidate: MainActivity) {
        if (activity?.get() === candidate) activityResumed = false
    }

    @Synchronized
    fun onActivityDestroyed(candidate: MainActivity) {
        if (activity?.get() === candidate) {
            activityResumed = false
            activity = null
            if (!state.shouldRetainEngine) engine = null
        }
    }

    @Synchronized
    fun onProjectionLease(next: CarProjectionSessionLeaseRuntime.Snapshot) {
        val priorGeneration = state.projectionGeneration
        state.onProjectionLease(next.active, next.generation)
        if (!next.active) {
            scheduleReleaseWatchdogLocked(next.generation)
        } else if (next.generation > priorGeneration) {
            cancelReleaseWatchdogLocked()
            releaseEngineIfUnownedLocked()
        }
        publishLocked()
    }

    @Synchronized
    override fun currentLease(): CarProjectionLeaseMessage = messageLocked()

    @Synchronized
    override fun armContinuity(projectionGeneration: Long, connectionGeneration: Long): CarProjectionLeaseMessage {
        val context = applicationContext
        if (context == null || !state.canStart(
                requestedProjectionGeneration = projectionGeneration,
                requestedConnectionGeneration = connectionGeneration,
                activityResumed = activityResumed,
                hasEngine = engine != null,
                projectionConnected = CarProjectionSessionLeaseRuntime.isProjectionConnected(),
            )
        ) return messageLocked()

        state.beginStart(projectionGeneration, connectionGeneration)
        try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, ProjectionForegroundService::class.java)
                    .putExtra(ProjectionForegroundService.EXTRA_PROJECTION_GENERATION, projectionGeneration)
                    .putExtra(ProjectionForegroundService.EXTRA_CONNECTION_GENERATION, connectionGeneration),
            )
        } catch (_: RuntimeException) {
            state.cancelStart(projectionGeneration, connectionGeneration)
        }
        return messageLocked()
    }

    @Synchronized
    override fun retireContinuity(projectionGeneration: Long, connectionGeneration: Long) {
        if (!state.retire(projectionGeneration, connectionGeneration)) return
        scheduleReleaseWatchdogLocked(projectionGeneration)
        applicationContext?.let { it.stopService(Intent(it, ProjectionForegroundService::class.java)) }
        publishLocked()
    }

    @Synchronized
    fun markServiceArmed(projectionGeneration: Long, connectionGeneration: Long): Boolean {
        if (!state.markArmed(projectionGeneration, connectionGeneration, engine != null)) return false
        cancelReleaseWatchdogLocked()
        publishLocked()
        return true
    }

    @Synchronized
    fun hasArmedService(): Boolean = state.armed

    @Synchronized
    fun markServiceStopped(projectionGeneration: Long, connectionGeneration: Long) {
        if (!state.serviceStopped(projectionGeneration, connectionGeneration)) return
        scheduleReleaseWatchdogLocked(projectionGeneration)
        publishLocked()
    }

    @Synchronized
    override fun acknowledgeRelease(projectionGeneration: Long) {
        if (!state.acknowledgeRelease(projectionGeneration)) return
        if (releaseWatchdogGeneration == projectionGeneration) cancelReleaseWatchdogLocked()
        applicationContext?.let { it.stopService(Intent(it, ProjectionForegroundService::class.java)) }
        if (activity?.get() == null) {
            val retiredEngine = engine
            engine = null
            // Let Pigeon's reply leave the engine messenger before detaching
            // the isolate that sent the exact drain acknowledgement.
            mainHandler.post { retiredEngine?.destroy() }
        }
    }

    private fun scheduleReleaseWatchdogLocked(projectionGeneration: Long) {
        cancelReleaseWatchdogLocked()
        releaseWatchdogGeneration = projectionGeneration
        val watchdog = Runnable {
            synchronized(this) {
                if (!state.forceRelease(projectionGeneration)) return@synchronized
                releaseWatchdogGeneration = null
                releaseWatchdog = null
                applicationContext?.let {
                    it.stopService(Intent(it, ProjectionForegroundService::class.java))
                }
                if (!activityResumed) {
                    val retiredEngine = engine
                    engine = null
                    retiredEngine?.destroy()
                }
            }
        }
        releaseWatchdog = watchdog
        mainHandler.postDelayed(watchdog, RELEASE_ACK_TIMEOUT_MS)
    }

    private fun cancelReleaseWatchdogLocked() {
        releaseWatchdog?.let(mainHandler::removeCallbacks)
        releaseWatchdog = null
        releaseWatchdogGeneration = null
    }

    private fun releaseEngineIfUnownedLocked() {
        if (activity?.get() != null || state.shouldRetainEngine) return
        val retiredEngine = engine
        engine = null
        mainHandler.post { retiredEngine?.destroy() }
    }

    @Synchronized
    fun retainedEngine(): FlutterEngine? = engine.takeIf { shouldRetainEngine() }

    @Synchronized
    fun shouldRetainEngine(): Boolean = state.shouldRetainEngine

    @Synchronized
    private fun messageLocked() = CarProjectionLeaseMessage(
        active = state.projectionActive,
        generation = state.projectionGeneration,
        armed = state.armed,
        connectionGeneration = state.connectionGeneration,
    )

    private fun publishLocked() {
        val messenger = engine?.dartExecutor?.binaryMessenger ?: return
        val message = messageLocked()
        scope.launch { runCatching { CarProjectionSessionFlutterApi(messenger).onLeaseChanged(message) } }
    }

    private const val RELEASE_ACK_TIMEOUT_MS = 8_000L
}

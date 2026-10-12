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
import io.flutter.embedding.engine.dart.DartExecutor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference

internal object ProjectionContinuityRuntime : CarProjectionSessionHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var applicationContext: Context? = null
    private val engineOwner = ProjectionEngineOwner<FlutterEngine>()
    private var activity: WeakReference<MainActivity>? = null
    private var activityResumed = false
    private var carServiceActive = false
    private val state = ProjectionContinuityState()
    private var releaseWatchdogGeneration: Long? = null
    private var releaseWatchdog: Runnable? = null

    @Synchronized
    fun registerEngine(next: FlutterEngine) {
        if (!engineOwner.adopt(next)) return
        CarProjectionSessionHostApi.setUp(next.dartExecutor.binaryMessenger, this)
        publishLocked()
    }

    @Synchronized
    fun onCarServiceStarted(context: Context) {
        applicationContext = context.applicationContext
        carServiceActive = true
        CarProjectionSessionLeaseRuntime.installProjectionConnectionGuard(context.applicationContext)
        if (engineOwner.current() != null) return

        RendererProcessRuntime.initialize(context.applicationContext, emptyArray())
        val created = FlutterEngine(context.applicationContext)
        try {
            ApplicationPlatformChannels.register(
                flutterEngine = created,
                context = context.applicationContext,
                renderer = RendererProcessRuntime.label(),
                rendererReason = RendererProcessRuntime.reason(),
            )
            FlavorPlatformRegistrar.register(created)
            check(engineOwner.current() === created) { "Projected engine was not registered" }
            created.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        } catch (error: Throwable) {
            engineOwner.clearIf(created)
            created.destroy()
            throw error
        }
    }

    @Synchronized
    fun onCarServiceStopped() {
        carServiceActive = false
        releaseEngineIfUnownedLocked()
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
            if (!shouldRetainEngineLocked()) engineOwner.current()?.let(engineOwner::clearIf)
        }
    }

    @Synchronized
    fun onProjectionLease(next: CarProjectionSessionLeaseRuntime.Snapshot) {
        val priorGeneration = state.projectionGeneration
        val priorConnectionGeneration = state.connectionGeneration
        state.onProjectionLease(next.active, next.generation)
        if (!next.active && state.releaseAwaitingAck == next.generation) {
            scheduleReleaseWatchdogLocked(next.generation)
        } else if (next.active && next.generation > priorGeneration) {
            if (!state.shouldHoldWakeLock) {
                ProjectionForegroundService.setProjectionArmed(
                    priorConnectionGeneration,
                    armed = false,
                )
            }
            if (state.releaseAwaitingAck == null) cancelReleaseWatchdogLocked()
            releaseEngineIfUnownedLocked()
        }
        publishLocked()
    }

    @Synchronized
    override fun currentLease(): CarProjectionLeaseMessage = messageLocked()

    @Synchronized
    override fun claimProducerConnection(connectionGeneration: Long): CarProjectionLeaseMessage {
        if (state.producerConnectionGeneration == connectionGeneration) return messageLocked()
        val context = applicationContext
        if (context == null || !state.canClaimProducer(
                requestedConnectionGeneration = connectionGeneration,
                producerStartAuthorized = activityResumed ||
                    (carServiceActive && state.projectionActive),
                hasEngine = engineOwner.current() != null,
            )
        ) return messageLocked()

        state.beginProducerClaim(connectionGeneration)
        try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, ProjectionForegroundService::class.java)
                    .setAction(ProjectionForegroundService.ACTION_CLAIM_PRODUCER)
                    .putExtra(ProjectionForegroundService.EXTRA_CONNECTION_GENERATION, connectionGeneration),
            )
        } catch (_: RuntimeException) {
            state.cancelProducerClaim(connectionGeneration)
        }
        return messageLocked()
    }

    @Synchronized
    override fun retireProducerConnection(connectionGeneration: Long) {
        if (!state.retireProducer(connectionGeneration)) return
        cancelReleaseWatchdogLocked()
        ProjectionForegroundService.stopProducer(connectionGeneration)
        publishLocked()
        releaseEngineIfUnownedLocked()
    }

    @Synchronized
    override fun armContinuity(projectionGeneration: Long, connectionGeneration: Long): CarProjectionLeaseMessage {
        if (!state.canArm(
                requestedProjectionGeneration = projectionGeneration,
                requestedConnectionGeneration = connectionGeneration,
                hasEngine = engineOwner.current() != null,
                projectionConnected = CarProjectionSessionLeaseRuntime.isProjectionConnected(),
            )
        ) return messageLocked()

        if (!state.markArmed(projectionGeneration, connectionGeneration)) return messageLocked()
        if (!ProjectionForegroundService.setProjectionArmed(connectionGeneration, armed = true)) {
            state.serviceStopped(connectionGeneration)
            publishLocked()
            releaseEngineIfUnownedLocked()
            return messageLocked()
        }
        cancelReleaseWatchdogLocked()
        publishLocked()
        return messageLocked()
    }

    @Synchronized
    override fun retireContinuity(projectionGeneration: Long, connectionGeneration: Long) {
        if (!state.retireProjection(projectionGeneration, connectionGeneration)) return
        scheduleReleaseWatchdogLocked(projectionGeneration)
        publishLocked()
    }

    @Synchronized
    override fun acknowledgeRelease(projectionGeneration: Long) {
        val connectionGeneration = state.releaseConnectionGeneration
        if (!state.acknowledgeRelease(projectionGeneration)) return
        if (releaseWatchdogGeneration == projectionGeneration) cancelReleaseWatchdogLocked()
        ProjectionForegroundService.setProjectionArmed(connectionGeneration, armed = false)
        publishLocked()
        releaseEngineIfUnownedLocked()
    }

    @Synchronized
    fun markServiceProducerConfirmed(connectionGeneration: Long): Boolean {
        val priorReleaseGeneration = state.releaseAwaitingAck
        if (!state.confirmProducer(connectionGeneration, engineOwner.current() != null)) return false
        if (priorReleaseGeneration != null && state.releaseAwaitingAck == null) {
            cancelReleaseWatchdogLocked()
        }
        publishLocked()
        return true
    }

    @Synchronized
    fun markServiceStopped(connectionGeneration: Long) {
        if (!state.serviceStopped(connectionGeneration)) return
        cancelReleaseWatchdogLocked()
        publishLocked()
        releaseEngineIfUnownedLocked()
    }

    @Synchronized
    fun hasProducerOwnerOrPendingClaim(): Boolean = state.hasProducerOrPending

    @Synchronized
    fun isProjectionArmedFor(connectionGeneration: Long): Boolean =
        state.armed && state.connectionGeneration == connectionGeneration

    private fun scheduleReleaseWatchdogLocked(projectionGeneration: Long) {
        cancelReleaseWatchdogLocked()
        releaseWatchdogGeneration = projectionGeneration
        val watchdog = Runnable {
            synchronized(this) {
                val producerGeneration = state.forceRelease(projectionGeneration) ?: return@synchronized
                releaseWatchdogGeneration = null
                releaseWatchdog = null
                ProjectionForegroundService.stopProducer(producerGeneration)
                publishLocked()
                releaseEngineIfUnownedLocked()
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
        if (activity?.get() != null || shouldRetainEngineLocked()) return
        val retiredEngine = engineOwner.current() ?: return
        if (!engineOwner.clearIf(retiredEngine)) return
        mainHandler.post { retiredEngine?.destroy() }
    }

    @Synchronized
    fun retainedEngine(): FlutterEngine? = engineOwner.current()

    @Synchronized
    fun ownsEngine(candidate: FlutterEngine): Boolean = engineOwner.current() === candidate

    @Synchronized
    fun shouldRetainEngine(): Boolean = shouldRetainEngineLocked()

    private fun shouldRetainEngineLocked(): Boolean = carServiceActive || state.shouldRetainEngine

    @Synchronized
    private fun messageLocked() = CarProjectionLeaseMessage(
        active = state.projectionActive,
        generation = state.projectionGeneration,
        armed = state.armed,
        connectionGeneration = state.connectionGeneration,
        producerConnectionGeneration = state.producerConnectionGeneration,
    )

    private fun publishLocked() {
        val messenger = engineOwner.current()?.dartExecutor?.binaryMessenger ?: return
        val message = messageLocked()
        scope.launch { runCatching { CarProjectionSessionFlutterApi(messenger).onLeaseChanged(message) } }
    }

    private const val RELEASE_ACK_TIMEOUT_MS = 8_000L
}

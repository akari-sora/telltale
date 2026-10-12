package com.cbstudio.telltale

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.lang.ref.WeakReference

class ProjectionForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var connectionGeneration = -1L
    private var latestStartId = -1

    override fun onCreate() {
        super.onCreate()
        synchronized(serviceLock) {
            activeService = WeakReference(this)
        }
        if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.projection_notification_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        startInForeground(notification(liveTelemetry = false))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val requestedConnectionGeneration =
            intent?.getLongExtra(EXTRA_CONNECTION_GENERATION, -1) ?: -1
        latestStartId = startId
        val priorConnectionGeneration = connectionGeneration
        val isProducerClaim = intent?.action == ACTION_CLAIM_PRODUCER
        if (isProducerClaim) connectionGeneration = requestedConnectionGeneration
        if (isProducerClaim &&
            ProjectionContinuityRuntime.markServiceProducerConfirmed(requestedConnectionGeneration)
        ) {
            connectionGeneration = requestedConnectionGeneration
            setProjectionArmed(
                ProjectionContinuityRuntime.isProjectionArmedFor(requestedConnectionGeneration),
            )
        } else {
            connectionGeneration = priorConnectionGeneration
            if (!ProjectionContinuityRuntime.hasProducerOwnerOrPendingClaim()) {
                stopSelfResult(startId)
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releaseWakeLock()
        synchronized(serviceLock) {
            if (activeService?.get() === this) activeService = null
        }
        ProjectionContinuityRuntime.markServiceStopped(connectionGeneration)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun setProjectionArmed(armed: Boolean) {
        if (armed) acquireWakeLock() else releaseWakeLock()
        updatePresentation(liveTelemetry = armed)
    }

    private fun stopProducer(connectionGeneration: Long): Boolean {
        if (this.connectionGeneration != connectionGeneration) return false
        setProjectionArmed(armed = false)
        return stopSelfResult(latestStartId)
    }

    private fun startInForeground(notification: android.app.Notification) {
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updatePresentation(liveTelemetry: Boolean) {
        getSystemService(NotificationManager::class.java).notify(
            NOTIFICATION_ID,
            notification(liveTelemetry),
        )
    }

    private fun notification(liveTelemetry: Boolean) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(getString(R.string.projection_notification_title))
            .setContentText(
                if (liveTelemetry) {
                    getString(R.string.projection_notification_live_body)
                } else {
                    getString(R.string.projection_notification_waiting_body)
                },
            )
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

    @SuppressLint("WakelockTimeout")
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        wakeLock = getSystemService(PowerManager::class.java).newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:android-auto-telemetry",
        ).apply { acquire() }
    }

    private fun releaseWakeLock() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
    }

    companion object {
        const val ACTION_CLAIM_PRODUCER = "com.cbstudio.telltale.action.CLAIM_PRODUCER"
        const val EXTRA_CONNECTION_GENERATION = "connectionGeneration"
        private const val CHANNEL_ID = "android_auto_telemetry"
        private const val NOTIFICATION_ID = 4102
        private val serviceLock = Any()
        private var activeService: WeakReference<ProjectionForegroundService>? = null

        fun setProjectionArmed(connectionGeneration: Long?, armed: Boolean): Boolean {
            if (connectionGeneration == null) return false
            val service = synchronized(serviceLock) { activeService?.get() } ?: return false
            if (service.connectionGeneration != connectionGeneration) return false
            service.setProjectionArmed(armed)
            return true
        }

        fun stopProducer(connectionGeneration: Long): Boolean {
            val service = synchronized(serviceLock) { activeService?.get() } ?: return false
            return service.stopProducer(connectionGeneration)
        }
    }
}

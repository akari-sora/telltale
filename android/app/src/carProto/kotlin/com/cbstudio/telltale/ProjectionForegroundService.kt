package com.cbstudio.telltale

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class ProjectionForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var projectionGeneration = -1L
    private var connectionGeneration = -1L

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Android Auto telemetry",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("Telltale connected to Android Auto")
            .setContentText("Live vehicle telemetry is continuing for the car display")
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        wakeLock = getSystemService(PowerManager::class.java).newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:android-auto-telemetry",
        ).apply { acquire() }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val requestedProjectionGeneration =
            intent?.getLongExtra(EXTRA_PROJECTION_GENERATION, -1) ?: -1
        val requestedConnectionGeneration =
            intent?.getLongExtra(EXTRA_CONNECTION_GENERATION, -1) ?: -1
        if (ProjectionContinuityRuntime.markServiceArmed(
                requestedProjectionGeneration,
                requestedConnectionGeneration,
            )
        ) {
            projectionGeneration = requestedProjectionGeneration
            connectionGeneration = requestedConnectionGeneration
        } else if (!ProjectionContinuityRuntime.hasArmedService()) {
            stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        ProjectionContinuityRuntime.markServiceStopped(projectionGeneration, connectionGeneration)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val EXTRA_PROJECTION_GENERATION = "projectionGeneration"
        const val EXTRA_CONNECTION_GENERATION = "connectionGeneration"
        private const val CHANNEL_ID = "android_auto_telemetry"
        private const val NOTIFICATION_ID = 4102
    }
}

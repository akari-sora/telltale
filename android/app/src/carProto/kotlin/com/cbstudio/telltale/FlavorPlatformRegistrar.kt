package com.cbstudio.telltale

import android.content.Context
import com.cbstudio.telltale.car.CarProjectionSessionLeaseRuntime
import com.cbstudio.telltale.car.diagnostics.CarDtcRuntime
import com.cbstudio.telltale.car.telemetry.CarTelemetryRuntime
import com.cbstudio.telltale.carbridge.CarDiagnosticsHostApiImpl
import com.cbstudio.telltale.carbridge.CarTelemetryHostApiImpl
import com.cbstudio.telltale.carbridge.generated.CarDiagnosticsHostApi
import com.cbstudio.telltale.carbridge.generated.CarTelemetryHostApi
import io.flutter.embedding.engine.FlutterEngine

/**
 * carProto flavor hook called from MainActivity.configureFlutterEngine.
 *
 * Registers the receiving end of the one-way Dart -> Kotlin telemetry and diagnostics bridge.
 * field / rig / wear provide a no-op object with the same name, so src/main
 * never references car code and no reflection is involved.
 */
internal object FlavorPlatformRegistrar {
    private val engineRegistration = IdentityRegistrationGuard()

    fun register(flutterEngine: FlutterEngine) {
        if (!engineRegistration.admit(flutterEngine)) return
        CarTelemetryHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            CarTelemetryHostApiImpl(repository = CarTelemetryRuntime.repository),
        )
        CarDiagnosticsHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            CarDiagnosticsHostApiImpl(repository = CarDtcRuntime.repository),
        )
        ProjectionContinuityRuntime.registerEngine(flutterEngine)
        CarProjectionSessionLeaseRuntime.installSink { snapshot ->
            ProjectionContinuityRuntime.onProjectionLease(snapshot)
        }
    }

    fun provideFlutterEngine(context: Context): FlutterEngine? =
        ProjectionContinuityRuntime.retainedEngine()

    fun shouldDestroyEngineWithHost(): Boolean =
        !ProjectionContinuityRuntime.shouldRetainEngine()

    fun onActivityResumed(activity: MainActivity) =
        ProjectionContinuityRuntime.onActivityResumed(activity)

    fun onActivityPaused(activity: MainActivity) =
        ProjectionContinuityRuntime.onActivityPaused(activity)

    fun onActivityDestroyed(activity: MainActivity) =
        ProjectionContinuityRuntime.onActivityDestroyed(activity)
}

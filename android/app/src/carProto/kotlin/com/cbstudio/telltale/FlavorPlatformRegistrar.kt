package com.cbstudio.telltale

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
    fun register(flutterEngine: FlutterEngine) {
        CarTelemetryHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            CarTelemetryHostApiImpl(repository = CarTelemetryRuntime.repository),
        )
        CarDiagnosticsHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            CarDiagnosticsHostApiImpl(repository = CarDtcRuntime.repository),
        )
    }
}

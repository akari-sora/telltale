package com.cbstudio.telltale

import io.flutter.embedding.engine.FlutterEngine

/**
 * wear flavor: registers nothing.
 *
 * MainActivity calls this hook in every flavor; only carProto supplies a body
 * (the one-way car telemetry bridge). Keeping a same-named no-op here means
 * src/main never references car code and no reflection is needed.
 */
internal object FlavorPlatformRegistrar {
    fun register(flutterEngine: FlutterEngine) = Unit
}

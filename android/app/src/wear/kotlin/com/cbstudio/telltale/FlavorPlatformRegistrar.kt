package com.cbstudio.telltale

import android.content.Context
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
    fun provideFlutterEngine(context: Context): FlutterEngine? = null
    fun shouldDestroyEngineWithHost(): Boolean = true
    fun onActivityResumed(activity: MainActivity) = Unit
    fun onActivityPaused(activity: MainActivity) = Unit
    fun onActivityDestroyed(activity: MainActivity) = Unit
}

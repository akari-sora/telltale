package com.cbstudio.telltale

import android.os.Bundle
import java.lang.ref.WeakReference
import io.flutter.BuildConfig as FlutterBuildConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        applyRendererDecision()
        super.onCreate(savedInstanceState)
    }

    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? =
        FlavorPlatformRegistrar.provideFlutterEngine(context)

    override fun shouldDestroyEngineWithHost(): Boolean =
        FlavorPlatformRegistrar.shouldDestroyEngineWithHost()

    override fun onResume() {
        super.onResume()
        currentActivity = WeakReference(this)
        FlavorPlatformRegistrar.onActivityResumed(this)
    }

    override fun onPause() {
        FlavorPlatformRegistrar.onActivityPaused(this)
        clearCurrentActivity(this)
        super.onPause()
    }

    override fun onDestroy() {
        FlavorPlatformRegistrar.onActivityDestroyed(this)
        clearCurrentActivity(this)
        super.onDestroy()
    }

    /**
     * Decides the rendering backend and initialises the Flutter loader with it,
     * before the engine exists.
     *
     * The engine picks Impeller on every API 29+ device but a Vivante GPU,
     * and has no route back to Skia at runtime: when Vulkan is missing it
     * falls to its own OpenGL ES backend, and on an Adreno 330 that backend
     * dies in the driver's shader linker before the first frame
     * (ImL1s/telltale#121). The only lever an app holds that reaches Skia is
     * `--enable-impeller=false`, and a manifest entry would pull every phone
     * onto it. So the decision is per device, made here, and passed as a
     * shell argument that the engine's parser lets win over the manifest.
     * [RendererPolicy] is the whole of the rule and is unit-tested on the
     * JVM; this method only carries its answer across.
     *
     * Why before `super.onCreate()`: `FlutterActivity.onCreate` attaches its
     * delegate, which builds a `FlutterEngineGroup`, which initialises the
     * loader only if nothing has yet — and `ensureInitializationComplete` is a
     * no-op once it has run. The first caller in the process decides, so this
     * has to be it. `FlutterEngine`'s own documentation names exactly this
     * sequence as the way to pass VM arguments.
     *
     * In release the arguments are ours alone. The default path also parses
     * launch-Intent extras into shell arguments, so an exported activity could
     * be started into Skia on a modern phone while this code logged
     * `impeller-default`; flutter/flutter#190461 is the engine's own plan to
     * stop honouring those extras in release, and until it lands this does. In
     * debug and profile the extras are kept because `flutter run` delivers its
     * flags through them, and ours go last so the denylist still wins.
     */
    private fun applyRendererDecision() {
        RendererProcessRuntime.initialize(applicationContext, toolingShellArgs())
    }

    /**
     * The Intent-carried flags `flutter run` uses in debug and profile, and
     * nothing in release. `FlutterShellArgs` is deprecated in favour of
     * manifest metadata and is used here only on the side the tool needs.
     */
    @Suppress("DEPRECATION")
    private fun toolingShellArgs(): Array<String> =
        if (FlutterBuildConfig.RELEASE) emptyArray() else FlutterShellArgs.fromIntent(intent).toArray()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // A car-service cold start creates and auto-registers this engine
        // before an Activity exists. Do not register plugins a second time
        // when the phone UI later attaches to that exact process engine.
        if (!FlavorPlatformRegistrar.ownsProcessEngine(flutterEngine)) {
            super.configureFlutterEngine(flutterEngine)
        }
        ApplicationPlatformChannels.register(
            flutterEngine = flutterEngine,
            context = applicationContext,
            renderer = RendererProcessRuntime.label(),
            rendererReason = RendererProcessRuntime.reason(),
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_WAKE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "keepOn" -> {
                    // A driving dashboard that dozes off mid-corner is worse
                    // than the battery it saves. Scoped to this window only:
                    // the flag clears with the activity, so a crash cannot
                    // leave the screen pinned on.
                    val on = call.argument<Boolean>("on") == true
                    val activeWindow = currentActivity?.get()?.window
                    if (activeWindow == null) {
                        result.error("activity_unavailable", "No resumed Activity window", null)
                    } else if (on) {
                        activeWindow.addFlags(
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        )
                    } else {
                        activeWindow.clearFlags(
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        )
                    }
                    if (activeWindow != null) result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HUD_DISPLAY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBrightnessOverride" -> {
                    val brightness = call.argument<Double?>("brightness")
                    val activeWindow = currentActivity?.get()?.window
                    if (activeWindow == null) {
                        result.error("activity_unavailable", "No resumed Activity window", null)
                        return@setMethodCallHandler
                    }
                    val lp = activeWindow.attributes
                    if (brightness == null) {
                        lp.screenBrightness = android.view.WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    } else {
                        lp.screenBrightness = brightness.toFloat().coerceIn(0.0f, 1.0f)
                    }
                    activeWindow.attributes = lp
                    result.success(null)
                }
                "setSystemBarsHidden" -> {
                    val hidden = call.argument<Boolean>("hidden") ?: false
                    val activeWindow = currentActivity?.get()?.window
                    if (activeWindow == null) {
                        result.error("activity_unavailable", "No resumed Activity window", null)
                        return@setMethodCallHandler
                    }
                    val insetsController = androidx.core.view.WindowCompat.getInsetsController(activeWindow, activeWindow.decorView)
                    if (hidden) {
                        insetsController.systemBarsBehavior =
                            androidx.core.view.WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        insetsController.hide(androidx.core.view.WindowInsetsCompat.Type.systemBars())
                    } else {
                        insetsController.show(androidx.core.view.WindowInsetsCompat.Type.systemBars())
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Flavor-provided, resolved at compile time. field and carProto
        // register the one-way car telemetry bridge; rig / wear compile a no-op.
        // src/main must never name car types directly.
        FlavorPlatformRegistrar.register(flutterEngine)
    }

    private companion object {
        @Volatile
        var currentActivity: WeakReference<MainActivity>? = null

        fun clearCurrentActivity(activity: MainActivity) {
            if (currentActivity?.get() === activity) currentActivity = null
        }

        const val SCREEN_WAKE_CHANNEL = "com.cbstudio.telltale/screen_wake"
        const val HUD_DISPLAY_CHANNEL = "com.cbstudio.telltale/hud_display"
    }
}

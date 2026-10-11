package com.cbstudio.telltale

import android.os.Build
import android.os.Bundle
import android.util.Log
import java.lang.ref.WeakReference
import io.flutter.BuildConfig as FlutterBuildConfig
import io.flutter.FlutterInjector
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
        val decision = rendererDecision
        val loader = FlutterInjector.instance().flutterLoader()
        val initialised = loader.initialized()
        val applied = RendererPolicy.recordApplied(rendererApplied, initialised)
        if (initialised) {
            // Either this app applied the decision in an earlier activity of
            // this process (a warm relaunch), and it still stands; or
            // something else started the engine first, in which case the
            // decision was never applied and the metadata says so rather
            // than claiming a backend nobody asked for.
            rendererApplied = applied
            Log.i(
                TAG,
                if (applied) "renderer: ${decision.mode.label} (${decision.reason}), applied earlier in this process"
                else "renderer: ${decision.mode.label} not applied, engine initialised before MainActivity (${decision.reason})",
            )
            return
        }
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, toolingShellArgs() + decision.shellArgs)
        rendererApplied = applied
        Log.i(TAG, "renderer: ${decision.mode.label} (${decision.reason})")
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
        super.configureFlutterEngine(flutterEngine)
        ApplicationPlatformChannels.register(
            flutterEngine = flutterEngine,
            context = applicationContext,
            renderer = if (rendererApplied == true) rendererDecision.mode.label else UNKNOWN,
            rendererReason = rendererDecision.reason +
                (if (rendererApplied == true) "" else " (not applied: engine initialised before this app decided)"),
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

        // Flavor-provided, resolved at compile time. carProto registers the
        // one-way car telemetry bridge; field / rig / wear compile a no-op.
        // src/main must never name car types directly.
        FlavorPlatformRegistrar.register(flutterEngine)
    }

    private companion object {
        const val TAG = "Telltale"

        @Volatile
        var currentActivity: WeakReference<MainActivity>? = null

        fun clearCurrentActivity(activity: MainActivity) {
            if (currentActivity?.get() === activity) currentActivity = null
        }

        /**
         * Decided once per process. A recreated activity must not re-read the
         * properties and relabel a process that is already rendering on one
         * backend; and below the engine's own API gate nothing is read at all,
         * because the engine picks Skia there without being asked.
         */
        val rendererDecision: RendererDecision by lazy {
            val sdk = Build.VERSION.SDK_INT
            if (sdk < RendererPolicy.MIN_API_FOR_IMPELLER) {
                RendererPolicy.decide(sdk, null, null)
            } else {
                // One deadline for both reads, so the budget is per process
                // and not per property. What it bounds, and what it does not,
                // is on [DeviceProperties.read].
                val deadline = System.nanoTime() + DeviceProperties.DEFAULT_BUDGET_NANOS
                val board = DeviceProperties.read(RendererPolicy.BOARD_PLATFORM, deadline)
                val vulkan = DeviceProperties.read(RendererPolicy.VULKAN_HARDWARE, deadline)
                // Which path answered is worth one line each: whether
                // reflection survives the hidden-API policy on a given
                // Android release is only ever known from a run in the app.
                Log.i(TAG, "property ${RendererPolicy.BOARD_PLATFORM} via ${board.via}")
                Log.i(TAG, "property ${RendererPolicy.VULKAN_HARDWARE} via ${vulkan.via}")
                RendererPolicy.decide(sdk, board.value, vulkan.value)
            }
        }

        /** Null until [applyRendererDecision] has run in this process. */
        @Volatile
        var rendererApplied: Boolean? = null

        const val SCREEN_WAKE_CHANNEL = "com.cbstudio.telltale/screen_wake"
        const val HUD_DISPLAY_CHANNEL = "com.cbstudio.telltale/hud_display"
        const val UNKNOWN = "unknown"
    }
}

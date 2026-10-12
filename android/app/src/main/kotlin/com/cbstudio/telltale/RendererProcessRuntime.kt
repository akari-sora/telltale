package com.cbstudio.telltale

import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.FlutterInjector

/** Applies the renderer policy before whichever component creates the first engine. */
internal object RendererProcessRuntime {
    private const val TAG = "Telltale"
    private const val UNKNOWN = "unknown"

    private val decision: RendererDecision by lazy {
        val sdk = Build.VERSION.SDK_INT
        if (sdk < RendererPolicy.MIN_API_FOR_IMPELLER) {
            RendererPolicy.decide(sdk, null, null)
        } else {
            val deadline = System.nanoTime() + DeviceProperties.DEFAULT_BUDGET_NANOS
            val board = DeviceProperties.read(RendererPolicy.BOARD_PLATFORM, deadline)
            val vulkan = DeviceProperties.read(RendererPolicy.VULKAN_HARDWARE, deadline)
            Log.i(TAG, "property ${RendererPolicy.BOARD_PLATFORM} via ${board.via}")
            Log.i(TAG, "property ${RendererPolicy.VULKAN_HARDWARE} via ${vulkan.via}")
            RendererPolicy.decide(sdk, board.value, vulkan.value)
        }
    }

    @Volatile
    private var applied: Boolean? = null

    fun initialize(context: Context, toolingArgs: Array<String>) {
        val loader = FlutterInjector.instance().flutterLoader()
        val alreadyInitialized = loader.initialized()
        val wasApplied = RendererPolicy.recordApplied(applied, alreadyInitialized)
        if (alreadyInitialized) {
            applied = wasApplied
            Log.i(
                TAG,
                if (wasApplied) "renderer: ${decision.mode.label} (${decision.reason}), applied earlier in this process"
                else "renderer: ${decision.mode.label} not applied, engine initialised before app policy (${decision.reason})",
            )
            return
        }
        val app = context.applicationContext
        loader.startInitialization(app)
        loader.ensureInitializationComplete(app, toolingArgs + decision.shellArgs)
        applied = wasApplied
        Log.i(TAG, "renderer: ${decision.mode.label} (${decision.reason})")
    }

    fun label(): String = if (applied == true) decision.mode.label else UNKNOWN

    fun reason(): String = decision.reason +
        (if (applied == true) "" else " (not applied: engine initialised before this app decided)")
}

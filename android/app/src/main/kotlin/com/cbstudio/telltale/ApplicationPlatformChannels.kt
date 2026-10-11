package com.cbstudio.telltale

import android.app.LocaleManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.LocaleList
import android.os.StatFs
import android.os.SystemClock
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress

/** Process-safe channels that may outlive the Activity owning the engine. */
internal object ApplicationPlatformChannels {
    fun register(
        flutterEngine: FlutterEngine,
        context: Context,
        renderer: String,
        rendererReason: String,
    ) {
        val app = context.applicationContext
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, PLATFORM_METADATA_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPlatformMetadata") {
                result.success(platformMetadata(app, renderer, rendererReason))
            } else result.notImplemented()
        }
        MethodChannel(messenger, APP_STORAGE_CAPACITY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAvailableBytes") {
                appCacheAvailableBytes(app, call.argument("path"), result)
            } else result.notImplemented()
        }
        MethodChannel(messenger, WIFI_ROUTE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bind" -> bindWifiRoute(app, call.argument("host"), result)
                "release" -> releaseWifiRoute(app, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, FORM_FACTOR_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isWatch") {
                result.success(app.packageManager.hasSystemFeature(PackageManager.FEATURE_WATCH))
            } else result.notImplemented()
        }
        MethodChannel(messenger, ELAPSED_REALTIME_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "elapsedRealtimeMs") {
                result.success(SystemClock.elapsedRealtime())
            } else result.notImplemented()
        }
        MethodChannel(messenger, APP_LOCALES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppLocales" -> result.success(readAppLocales(app))
                "setAppLocales" -> setAppLocales(app, stringList(call.argument("tags")), result)
                else -> result.notImplemented()
            }
        }
    }

    private fun appCacheAvailableBytes(context: Context, path: String?, result: MethodChannel.Result) {
        try {
            val bytes = StatFs(if (path.isNullOrEmpty()) context.cacheDir.path else path).availableBytes
            if (bytes > 0L) result.success(bytes)
            else result.error("capacity_invalid", "Available bytes were not positive", null)
        } catch (error: Exception) {
            result.error("capacity_failed", error.message, null)
        }
    }

    private fun manager(context: Context, result: MethodChannel.Result): ConnectivityManager? =
        context.getSystemService(ConnectivityManager::class.java).also {
            if (it == null) result.error("no_connectivity_service", "ConnectivityManager is unavailable", null)
        }

    private fun bindWifiRoute(context: Context, host: String?, result: MethodChannel.Result) {
        val manager = manager(context, result) ?: return
        @Suppress("DEPRECATION")
        val wifi = manager.allNetworks.mapNotNull { network ->
            val capabilities = manager.getNetworkCapabilities(network)
            val link = manager.getLinkProperties(network)
            if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) != true ||
                link == null || link.linkAddresses.isEmpty()
            ) null else network to capabilities
        }
        if (wifi.isEmpty()) {
            result.error("no_wifi_network", "ConnectivityManager reports no TRANSPORT_WIFI network", null)
            return
        }
        val target = host?.takeIf(::isNumericHost)?.let { runCatching { InetAddress.getByName(it) }.getOrNull() }
        val keyed = wifi.map { (network, capabilities) ->
            network to Pair(
                target != null && linkContains(manager, network, target),
                !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
            )
        }.sortedWith(
            compareByDescending<Pair<android.net.Network, Pair<Boolean, Boolean>>> { it.second.first }
                .thenByDescending { it.second.second },
        )
        val top = keyed.filter { it.second == keyed.first().second }
        if (top.size > 1) {
            result.error("ambiguous_wifi_network", "${top.size} Wi-Fi networks are equally plausible routes toward the adapter", null)
            return
        }
        if (!manager.bindProcessToNetwork(keyed.first().first)) {
            result.error("bind_refused", "bindProcessToNetwork returned false for the selected Wi-Fi candidate", null)
            return
        }
        result.success(null)
    }

    private fun releaseWifiRoute(context: Context, result: MethodChannel.Result) {
        val manager = manager(context, result) ?: return
        if (!manager.bindProcessToNetwork(null)) {
            result.error("release_refused", "bindProcessToNetwork(null) returned false", null)
        } else result.success(null)
    }

    private fun isNumericHost(host: String): Boolean = when {
        host.contains(':') -> host.all { it.isDigit() || it in 'a'..'f' || it in 'A'..'F' || it == ':' || it == '.' }
        else -> host.matches(Regex("""\d{1,3}(\.\d{1,3}){3}"""))
    }

    private fun linkContains(manager: ConnectivityManager, network: android.net.Network, target: InetAddress): Boolean =
        manager.getLinkProperties(network)?.linkAddresses?.any {
            sameSubnet(it.address, target, it.prefixLength)
        } == true

    private fun sameSubnet(a: InetAddress, b: InetAddress, prefixLength: Int): Boolean {
        val left = a.address
        val right = b.address
        if (left.size != right.size) return false
        var bits = prefixLength
        for (index in left.indices) {
            if (bits <= 0) break
            val mask = if (bits >= 8) 0xFF else (0xFF shl (8 - bits)) and 0xFF
            if ((left[index].toInt() and mask) != (right[index].toInt() and mask)) return false
            bits -= 8
        }
        return true
    }

    private fun readAppLocales(context: Context): Map<String, Any> {
        val sdk = Build.VERSION.SDK_INT
        val configurationTags = languageTags(context.resources.configuration.locales)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return mapOf(
            "apiSupported" to false,
            "sdkInt" to sdk,
            "followsSystem" to true,
            "overrideTags" to emptyList<String>(),
            "configurationTags" to configurationTags,
        )
        return readAppLocalesApi33(context, sdk, configurationTags)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun readAppLocalesApi33(
        context: Context,
        sdk: Int,
        configurationTags: List<String>,
    ): Map<String, Any> {
        val app = context.getSystemService(LocaleManager::class.java)?.applicationLocales
            ?: LocaleList.getEmptyLocaleList()
        val override = AppLocalePolicy.overrideFromLocaleListTags(languageTags(app))
        return mapOf(
            "apiSupported" to true,
            "sdkInt" to sdk,
            "followsSystem" to override.followsSystem,
            "overrideTags" to override.tags,
            "configurationTags" to configurationTags,
        )
    }

    private fun setAppLocales(context: Context, tags: List<String>, result: MethodChannel.Result) {
        val sdk = Build.VERSION.SDK_INT
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.error("below_api_33", "LocaleManager applicationLocales requires API 33", mapOf("sdkInt" to sdk))
            return
        }
        val override = AppLocalePolicy.overrideFromRequestedTags(tags)
        if (override == null) {
            result.error("unsupported_locale", "not a shipped UI locale", mapOf("tags" to tags))
            return
        }
        setAppLocalesApi33(context, sdk, override, result)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun setAppLocalesApi33(
        context: Context,
        sdk: Int,
        override: AppLocaleOverride,
        result: MethodChannel.Result,
    ) {
        val manager = context.getSystemService(LocaleManager::class.java)
        if (manager == null) {
            result.error("no_locale_manager", "LocaleManager is unavailable", null)
            return
        }
        val encoded = AppLocalePolicy.languageTagsForLocaleList(override)
        manager.applicationLocales = if (encoded.isEmpty()) LocaleList.getEmptyLocaleList()
        else LocaleList.forLanguageTags(encoded)
        result.success(
            readAppLocalesApi33(
                context,
                sdk,
                languageTags(context.resources.configuration.locales),
            ),
        )
    }

    private fun languageTags(list: LocaleList): List<String> =
        (0 until list.size()).mapNotNull { list[it]?.toLanguageTag() }

    private fun stringList(raw: Any?): List<String> =
        (raw as? List<*>)?.mapNotNull { it as? String } ?: emptyList()

    @Suppress("DEPRECATION")
    private fun platformMetadata(context: Context, renderer: String, rendererReason: String): Map<String, Any> {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) packageInfo.longVersionCode
        else packageInfo.versionCode.toLong()
        return mapOf(
            "applicationId" to context.packageName,
            "appVersion" to (packageInfo.versionName ?: UNKNOWN),
            "appBuild" to versionCode.toString(),
            "platform" to "android",
            "osVersion" to (Build.VERSION.RELEASE ?: UNKNOWN),
            "manufacturer" to (Build.MANUFACTURER ?: UNKNOWN),
            "model" to (Build.MODEL ?: UNKNOWN),
            "sdkInt" to Build.VERSION.SDK_INT,
            "renderer" to renderer,
            "rendererReason" to rendererReason,
        )
    }

    private const val PLATFORM_METADATA_CHANNEL = "com.cbstudio.telltale/platform_metadata"
    private const val APP_STORAGE_CAPACITY_CHANNEL = "com.cbstudio.telltale/app_storage_capacity"
    private const val WIFI_ROUTE_CHANNEL = "com.cbstudio.telltale/wifi_route"
    private const val ELAPSED_REALTIME_CHANNEL = "com.cbstudio.telltale/elapsed_realtime"
    private const val FORM_FACTOR_CHANNEL = "com.cbstudio.telltale/form_factor"
    private const val APP_LOCALES_CHANNEL = "com.cbstudio.telltale/app_locales"
    private const val UNKNOWN = "unknown"
}

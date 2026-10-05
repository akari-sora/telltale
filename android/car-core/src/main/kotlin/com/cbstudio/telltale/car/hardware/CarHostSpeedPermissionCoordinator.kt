package com.cbstudio.telltale.car.hardware

import android.content.pm.PackageManager
import androidx.car.app.CarContext
import androidx.car.app.OnRequestPermissionsListener
import androidx.core.content.ContextCompat

/**
 * Manages runtime acquisition of vehicle speed permissions (AA05 Blocker 2).
 *
 * Adheres to:
 * - Manifest permissions for projected (com.google.android.gms.permission.CAR_SPEED)
 *   and automotive (android.car.permission.CAR_SPEED, android.car.permission.READ_CAR_DISPLAY_UNITS).
 * - Parked-only invocation (host rejects driving permission requests).
 * - Automatic retry of [CarHardwareSpeedGateway] upon user granting permission.
 */
class CarHostSpeedPermissionCoordinator(
    private val onPermissionGranted: () -> Unit = {},
) {
    companion object {
        const val PERMISSION_CAR_SPEED_PROJECTED = "com.google.android.gms.permission.CAR_SPEED"
        const val PERMISSION_CAR_SPEED_AUTOMOTIVE = "android.car.permission.CAR_SPEED"
        const val PERMISSION_READ_DISPLAY_UNITS = "android.car.permission.READ_CAR_DISPLAY_UNITS"

        fun resolveRequiredPermissions(carContext: CarContext): List<String> {
            val declared = try {
                val packageInfo = carContext.packageManager.getPackageInfo(
                    carContext.packageName,
                    PackageManager.GET_PERMISSIONS,
                )
                packageInfo.requestedPermissions?.toList() ?: emptyList()
            } catch (_: Throwable) {
                emptyList()
            }

            val needed = mutableListOf<String>()
            if (declared.contains(PERMISSION_CAR_SPEED_PROJECTED)) {
                needed.add(PERMISSION_CAR_SPEED_PROJECTED)
            }
            if (declared.contains(PERMISSION_CAR_SPEED_AUTOMOTIVE)) {
                needed.add(PERMISSION_CAR_SPEED_AUTOMOTIVE)
            }
            if (declared.contains(PERMISSION_READ_DISPLAY_UNITS)) {
                needed.add(PERMISSION_READ_DISPLAY_UNITS)
            }
            return needed
        }

        fun hasAllPermissions(carContext: CarContext): Boolean {
            val perms = resolveRequiredPermissions(carContext)
            if (perms.isEmpty()) return false
            return perms.all {
                ContextCompat.checkSelfPermission(carContext, it) == PackageManager.PERMISSION_GRANTED
            }
        }
    }

    fun requestPermissions(
        carContext: CarContext,
        onResult: ((allGranted: Boolean) -> Unit)? = null,
    ) {
        val permissions = resolveRequiredPermissions(carContext)
        if (permissions.isEmpty()) {
            onResult?.invoke(false)
            return
        }
        val listener = OnRequestPermissionsListener { grantedPermissions, _ ->
            val allGranted = permissions.all { grantedPermissions.contains(it) }
            if (allGranted) {
                onPermissionGranted()
            }
            onResult?.invoke(allGranted)
        }
        carContext.requestPermissions(permissions, listener)
    }
}

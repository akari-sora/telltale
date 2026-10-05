package com.cbstudio.telltale.car.hardware

import androidx.car.app.OnRequestPermissionsListener
import androidx.car.app.testing.TestCarContext
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarHostSpeedPermissionCoordinatorTest {

    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext(),
        )
    }

    @Test
    fun resolveRequiredPermissionsFailsClosedWhenNoneDeclared() {
        val permissions = CarHostSpeedPermissionCoordinator.resolveRequiredPermissions(carContext)
        assertTrue(permissions.isEmpty())
        assertFalse(CarHostSpeedPermissionCoordinator.hasAllPermissions(carContext))
    }

    @Test
    fun requestPermissionsFailsClosedWhenNoneDeclared() {
        var grantTriggered = false
        val coordinator = CarHostSpeedPermissionCoordinator(
            onPermissionGranted = { grantTriggered = true },
        )

        var resultGranted: Boolean? = null
        coordinator.requestPermissions(carContext) { granted ->
            resultGranted = granted
        }

        assertEquals(false, resultGranted)
        assertFalse(grantTriggered)
        // No permission request was dispatched to TestCarContext
        org.junit.Assert.assertNull(carContext.lastPermissionRequestInfo)
    }

    @Test
    fun requestPermissionsInvokesCallbackOnGrantWhenDeclared() {
        val packageInfo = carContext.packageManager.getPackageInfo(carContext.packageName, 0).apply {
            requestedPermissions = arrayOf(
                CarHostSpeedPermissionCoordinator.PERMISSION_CAR_SPEED_PROJECTED,
            )
        }
        org.robolectric.Shadows.shadowOf(carContext.packageManager).installPackage(packageInfo)

        val resolved = CarHostSpeedPermissionCoordinator.resolveRequiredPermissions(carContext)
        assertEquals(listOf(CarHostSpeedPermissionCoordinator.PERMISSION_CAR_SPEED_PROJECTED), resolved)

        var grantTriggered = false
        val coordinator = CarHostSpeedPermissionCoordinator(
            onPermissionGranted = { grantTriggered = true },
        )

        var resultGranted: Boolean? = null
        coordinator.requestPermissions(carContext) { granted ->
            resultGranted = granted
        }

        // Simulate grant in TestCarContext
        val info = carContext.lastPermissionRequestInfo
        info?.listener?.onRequestPermissionsResult(resolved, emptyList<String>())

        assertTrue(resultGranted == true)
        assertTrue(grantTriggered)
    }

    @Test
    fun requestPermissionsDoesNotTriggerCallbackOnRejectionWhenDeclared() {
        val packageInfo = carContext.packageManager.getPackageInfo(carContext.packageName, 0).apply {
            requestedPermissions = arrayOf(
                CarHostSpeedPermissionCoordinator.PERMISSION_CAR_SPEED_PROJECTED,
            )
        }
        org.robolectric.Shadows.shadowOf(carContext.packageManager).installPackage(packageInfo)

        val resolved = CarHostSpeedPermissionCoordinator.resolveRequiredPermissions(carContext)

        var grantTriggered = false
        val coordinator = CarHostSpeedPermissionCoordinator(
            onPermissionGranted = { grantTriggered = true },
        )

        var resultGranted: Boolean? = null
        coordinator.requestPermissions(carContext) { granted ->
            resultGranted = granted
        }

        val info = carContext.lastPermissionRequestInfo
        info?.listener?.onRequestPermissionsResult(emptyList<String>(), resolved)

        assertTrue(resultGranted == false)
        assertFalse(grantTriggered)
    }
}

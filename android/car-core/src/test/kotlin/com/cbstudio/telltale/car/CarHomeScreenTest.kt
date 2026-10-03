package com.cbstudio.telltale.car

import androidx.car.app.model.PaneTemplate
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CarHomeScreenTest {

    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        carContext =
            TestCarContext.createCarContext(
                ApplicationProvider.getApplicationContext(),
            )
    }

    @Test
    fun homeScreen_returnsReadOnlyPaneTemplate() {
        val screen = CarHomeScreen(carContext)
        val controller = ScreenController(screen)

        controller.moveToState(androidx.lifecycle.Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as PaneTemplate

        assertEquals("Telltale", template.title.toString())
        assertEquals(3, template.pane.rows.size)

        // AA-01 is intentionally read-only.
        assertTrue(template.pane.actions.isEmpty())
    }

    @Test
    fun homeScreen_containsOnlySkeletonStatusRows() {
        val screen = CarHomeScreen(carContext)
        val controller = ScreenController(screen)

        controller.moveToState(androidx.lifecycle.Lifecycle.State.RESUMED)

        val template = screen.onGetTemplate() as PaneTemplate

        val titles =
            template.pane.rows
                .map { it.title.toString() }

        assertEquals(
            listOf(
                "Vehicle monitor",
                "Vehicle data",
                "Read-only projection",
            ),
            titles,
        )
    }
}

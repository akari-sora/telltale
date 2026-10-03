package com.cbstudio.telltale.car

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template

class CarHomeScreen(
    carContext: CarContext,
) : Screen(carContext) {

    @Suppress("DEPRECATION")
    override fun onGetTemplate(): Template {
        val pane =
            Pane.Builder()
                .addRow(
                    Row.Builder()
                        .setTitle(carContext.getString(R.string.car_home_status_title))
                        .addText(carContext.getString(R.string.car_home_status_body))
                        .build(),
                )
                .addRow(
                    Row.Builder()
                        .setTitle(carContext.getString(R.string.car_home_data_title))
                        .addText(carContext.getString(R.string.car_home_data_body))
                        .build(),
                )
                .addRow(
                    Row.Builder()
                        .setTitle(carContext.getString(R.string.car_home_safety_title))
                        .addText(carContext.getString(R.string.car_home_safety_body))
                        .build(),
                )
                .build()

        return PaneTemplate.Builder(pane)
            .setTitle(carContext.getString(R.string.car_app_name))
            .setHeaderAction(Action.APP_ICON)
            .build()
    }
}

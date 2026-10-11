package com.cbstudio.telltale.car

import androidx.car.app.CarContext
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat

internal enum class CarMetricIcon(
    val drawableRes: Int,
) {
    SPEED(R.drawable.ic_car_metric_speed),
    RPM(R.drawable.ic_car_metric_rpm),
    TEMPERATURE(R.drawable.ic_car_metric_temperature),
    VOLTAGE(R.drawable.ic_car_metric_battery),
    PRESSURE(R.drawable.ic_car_metric_pressure),
    LOAD(R.drawable.ic_car_metric_load),
    HEALTH(R.drawable.ic_car_metric_health),
    MIL(R.drawable.ic_car_metric_engine),
    DTC(R.drawable.ic_car_metric_dtc),
}

internal fun CarMetricIcon.toCarIcon(
    carContext: CarContext,
    warning: Boolean = false,
): CarIcon = CarIcon.Builder(
    IconCompat.createWithResource(carContext, drawableRes),
)
    .setTint(if (warning) CarColor.RED else CarColor.DEFAULT)
    .build()

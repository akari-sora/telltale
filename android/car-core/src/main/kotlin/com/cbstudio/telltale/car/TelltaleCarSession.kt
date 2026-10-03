package com.cbstudio.telltale.car

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

class TelltaleCarSession : Session() {

    override fun onCreateScreen(intent: Intent): Screen {
        return CarHomeScreen(carContext)
    }
}

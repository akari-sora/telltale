package com.cbstudio.telltale.car

/**
 * Application-owned process bootstrap used when Android Auto starts the car
 * service before the phone Activity has ever existed.
 */
interface CarProcessBootstrap {
    fun ensureCarRuntimeStarted()
    fun releaseCarRuntimeIfIdle()
}

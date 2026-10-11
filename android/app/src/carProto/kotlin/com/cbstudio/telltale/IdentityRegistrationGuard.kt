package com.cbstudio.telltale

/** Admits setup once per engine identity, including Activity recreation. */
internal class IdentityRegistrationGuard {
    private var registered: Any? = null

    @Synchronized
    fun admit(candidate: Any): Boolean {
        if (registered === candidate) return false
        registered = candidate
        return true
    }
}

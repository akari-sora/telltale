package com.cbstudio.telltale

/** Exact-identity holder for the single process Flutter engine. */
internal class ProjectionEngineOwner<T : Any> {
    private var current: T? = null

    fun current(): T? = current

    fun adopt(candidate: T): Boolean {
        if (current === candidate) return false
        check(current == null) { "A different projection engine is already active" }
        current = candidate
        return true
    }

    fun clearIf(candidate: T): Boolean {
        if (current !== candidate) return false
        current = null
        return true
    }
}

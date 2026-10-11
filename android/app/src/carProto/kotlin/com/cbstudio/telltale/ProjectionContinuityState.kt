package com.cbstudio.telltale

/** Pure ownership state for the carProto continuity service. */
internal class ProjectionContinuityState {
    var projectionActive: Boolean = false
        private set
    var projectionGeneration: Long = 0
        private set
    var armedGeneration: Long? = null
        private set
    var connectionGeneration: Long? = null
        private set
    private var pendingProjectionGeneration: Long? = null
    private var highestStartAttemptGeneration: Long = -1
    var releaseAwaitingAck: Long? = null
        private set

    fun onProjectionLease(active: Boolean, generation: Long) {
        val supersedesPendingGeneration =
            active && generation > projectionGeneration && pendingProjectionGeneration != null
        val supersedesReleasedGeneration =
            active && generation > projectionGeneration && releaseAwaitingAck != null
        if (supersedesPendingGeneration || supersedesReleasedGeneration) {
            releaseAwaitingAck = null
            armedGeneration = null
            pendingProjectionGeneration = null
            connectionGeneration = null
        }
        projectionActive = active
        projectionGeneration = generation
        if (!active && armedGeneration == generation) releaseAwaitingAck = generation
    }

    fun canStart(
        requestedProjectionGeneration: Long,
        requestedConnectionGeneration: Long,
        activityResumed: Boolean,
        hasEngine: Boolean,
        projectionConnected: Boolean,
    ): Boolean =
        projectionActive &&
            projectionGeneration == requestedProjectionGeneration &&
            requestedConnectionGeneration > 0 &&
            pendingProjectionGeneration == null &&
            (activityResumed || requestedProjectionGeneration > highestStartAttemptGeneration) &&
            hasEngine &&
            projectionConnected

    fun beginStart(projectionGeneration: Long, connectionGeneration: Long) {
        if (projectionGeneration > highestStartAttemptGeneration) {
            highestStartAttemptGeneration = projectionGeneration
        }
        pendingProjectionGeneration = projectionGeneration
        this.connectionGeneration = connectionGeneration
    }

    fun cancelStart(projectionGeneration: Long, connectionGeneration: Long) {
        if (pendingProjectionGeneration != projectionGeneration ||
            this.connectionGeneration != connectionGeneration || armedGeneration != null
        ) return
        pendingProjectionGeneration = null
        this.connectionGeneration = null
    }

    fun markArmed(projectionGeneration: Long, connectionGeneration: Long, hasEngine: Boolean): Boolean {
        if (!projectionActive || this.projectionGeneration != projectionGeneration ||
            pendingProjectionGeneration != projectionGeneration ||
            this.connectionGeneration != connectionGeneration || !hasEngine
        ) return false
        if (projectionGeneration > highestStartAttemptGeneration) {
            highestStartAttemptGeneration = projectionGeneration
        }
        armedGeneration = projectionGeneration
        pendingProjectionGeneration = null
        releaseAwaitingAck = null
        return true
    }

    fun retire(projectionGeneration: Long, connectionGeneration: Long): Boolean {
        if (armedGeneration != projectionGeneration ||
            this.connectionGeneration != connectionGeneration
        ) return false
        armedGeneration = null
        pendingProjectionGeneration = null
        this.connectionGeneration = null
        releaseAwaitingAck = projectionGeneration
        return true
    }

    fun serviceStopped(projectionGeneration: Long, connectionGeneration: Long): Boolean {
        if (armedGeneration == projectionGeneration &&
            this.connectionGeneration == connectionGeneration
        ) return retire(projectionGeneration, connectionGeneration)
        if (pendingProjectionGeneration != projectionGeneration ||
            this.connectionGeneration != connectionGeneration
        ) return false
        pendingProjectionGeneration = null
        this.connectionGeneration = null
        return true
    }

    fun acknowledgeRelease(projectionGeneration: Long): Boolean {
        if (releaseAwaitingAck != projectionGeneration) return false
        if (projectionActive && this.projectionGeneration != projectionGeneration) return false
        releaseAwaitingAck = null
        armedGeneration = null
        pendingProjectionGeneration = null
        connectionGeneration = null
        return true
    }

    fun forceRelease(projectionGeneration: Long): Boolean =
        acknowledgeRelease(projectionGeneration)

    val armed: Boolean
        get() = projectionActive && armedGeneration == projectionGeneration

    val shouldRetainEngine: Boolean
        get() = armedGeneration != null || releaseAwaitingAck != null
}

package com.cbstudio.telltale

/** Pure ownership state for the user-started OBD producer and Android Auto projection. */
internal class ProjectionContinuityState {
    var projectionActive: Boolean = false
        private set
    var projectionGeneration: Long = 0
        private set
    var armedGeneration: Long? = null
        private set
    var connectionGeneration: Long? = null
        private set
    var producerConnectionGeneration: Long? = null
        private set
    private var pendingProducerConnectionGeneration: Long? = null
    var releaseAwaitingAck: Long? = null
        private set
    var releaseConnectionGeneration: Long? = null
        private set

    fun onProjectionLease(active: Boolean, generation: Long) {
        if (active && generation > projectionGeneration) clearProjectionAttachment()
        projectionActive = active
        projectionGeneration = generation
        if (!active && armedGeneration == generation) {
            releaseAwaitingAck = generation
            releaseConnectionGeneration = connectionGeneration
        }
    }

    fun canClaimProducer(
        requestedConnectionGeneration: Long,
        activityResumed: Boolean,
        hasEngine: Boolean,
    ): Boolean =
        requestedConnectionGeneration > 0 &&
            activityResumed &&
            hasEngine &&
            producerConnectionGeneration != requestedConnectionGeneration &&
            pendingProducerConnectionGeneration != requestedConnectionGeneration

    fun beginProducerClaim(connectionGeneration: Long) {
        pendingProducerConnectionGeneration = connectionGeneration
    }

    fun cancelProducerClaim(connectionGeneration: Long) {
        if (pendingProducerConnectionGeneration == connectionGeneration) {
            pendingProducerConnectionGeneration = null
        }
    }

    fun confirmProducer(connectionGeneration: Long, hasEngine: Boolean): Boolean {
        if (connectionGeneration <= 0 ||
            pendingProducerConnectionGeneration != connectionGeneration ||
            !hasEngine
        ) return false
        producerConnectionGeneration = connectionGeneration
        pendingProducerConnectionGeneration = null
        if (this.connectionGeneration != null && this.connectionGeneration != connectionGeneration) {
            clearProjectionAttachment()
        }
        if (releaseConnectionGeneration != null && releaseConnectionGeneration != connectionGeneration) {
            clearPendingRelease()
        }
        return true
    }

    fun retireProducer(connectionGeneration: Long): Boolean {
        val ownsConfirmed = producerConnectionGeneration == connectionGeneration
        val ownsPending = pendingProducerConnectionGeneration == connectionGeneration
        if (!ownsConfirmed && !ownsPending) return false
        if (ownsConfirmed) producerConnectionGeneration = null
        if (ownsPending) pendingProducerConnectionGeneration = null
        if (this.connectionGeneration == connectionGeneration) clearProjectionAttachment()
        if (releaseConnectionGeneration == connectionGeneration) clearPendingRelease()
        return true
    }

    fun canArm(
        requestedProjectionGeneration: Long,
        requestedConnectionGeneration: Long,
        hasEngine: Boolean,
        projectionConnected: Boolean,
    ): Boolean =
        projectionActive &&
            projectionGeneration == requestedProjectionGeneration &&
            requestedConnectionGeneration > 0 &&
            producerConnectionGeneration == requestedConnectionGeneration &&
            hasEngine &&
            projectionConnected

    fun markArmed(projectionGeneration: Long, connectionGeneration: Long): Boolean {
        if (!canArm(
                requestedProjectionGeneration = projectionGeneration,
                requestedConnectionGeneration = connectionGeneration,
                hasEngine = true,
                projectionConnected = true,
            )
        ) return false
        armedGeneration = projectionGeneration
        this.connectionGeneration = connectionGeneration
        clearPendingRelease()
        return true
    }

    fun retireProjection(projectionGeneration: Long, connectionGeneration: Long): Boolean {
        if (armedGeneration != projectionGeneration ||
            this.connectionGeneration != connectionGeneration
        ) return false
        armedGeneration = null
        releaseAwaitingAck = projectionGeneration
        releaseConnectionGeneration = connectionGeneration
        return true
    }

    fun acknowledgeRelease(projectionGeneration: Long): Boolean {
        if (releaseAwaitingAck != projectionGeneration) return false
        clearPendingRelease()
        if (!projectionActive && this.projectionGeneration == projectionGeneration) {
            clearProjectionAttachment()
        }
        return true
    }

    /**
     * Fails closed when Dart never acknowledges a drained projection.
     * Returns the exact producer generation that was retired, if it still owns the drain.
     */
    fun forceRelease(projectionGeneration: Long): Long? {
        if (releaseAwaitingAck != projectionGeneration) return null
        val associatedConnection = releaseConnectionGeneration ?: return null
        if (producerConnectionGeneration != associatedConnection) return null
        producerConnectionGeneration = null
        if (pendingProducerConnectionGeneration == associatedConnection) {
            pendingProducerConnectionGeneration = null
        }
        if (connectionGeneration == associatedConnection) clearProjectionAttachment()
        clearPendingRelease()
        return associatedConnection
    }

    fun serviceStopped(connectionGeneration: Long): Boolean {
        if (producerConnectionGeneration != connectionGeneration &&
            pendingProducerConnectionGeneration != connectionGeneration
        ) return false
        return retireProducer(connectionGeneration)
    }

    val armed: Boolean
        get() = projectionActive &&
            armedGeneration == projectionGeneration &&
            connectionGeneration == producerConnectionGeneration

    val hasProducerOrPending: Boolean
        get() = producerConnectionGeneration != null || pendingProducerConnectionGeneration != null

    val shouldRetainEngine: Boolean
        get() = hasProducerOrPending || releaseAwaitingAck != null

    val shouldHoldWakeLock: Boolean
        get() = armed ||
            (releaseAwaitingAck != null &&
                releaseConnectionGeneration == producerConnectionGeneration)

    private fun clearProjectionAttachment() {
        armedGeneration = null
        connectionGeneration = null
    }

    private fun clearPendingRelease() {
        releaseAwaitingAck = null
        releaseConnectionGeneration = null
    }
}

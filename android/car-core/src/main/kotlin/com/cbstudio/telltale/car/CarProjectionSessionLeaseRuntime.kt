package com.cbstudio.telltale.car

import android.content.Context
import androidx.car.app.connection.CarConnection
import androidx.lifecycle.Observer

/** Process-scoped identity lease for a live projected [TelltaleCarSession]. */
object CarProjectionSessionLeaseRuntime {
    data class Snapshot(
        val active: Boolean,
        val generation: Long,
    )

    class Token internal constructor(
        internal val identity: Any,
        val generation: Long,
    )

    fun interface Sink {
        fun onChanged(snapshot: Snapshot)
    }

    private var generation = 0L
    private val tokens = mutableMapOf<Any, Token>()
    private var currentConnectionAttested = false
    private var sink: Sink? = null
    private var carConnection: CarConnection? = null
    private var observedConnectionType: Int? = null
    private val connectionObserver = Observer<Int>(::onConnectionTypeChanged)

    @Synchronized
    fun installProjectionConnectionGuard(context: Context) {
        if (carConnection != null) return
        carConnection = CarConnection(context.applicationContext).also {
            it.type.observeForever(connectionObserver)
        }
    }

    @Synchronized
    fun isProjectionConnected(): Boolean =
        carConnection?.type?.value == CarConnection.CONNECTION_TYPE_PROJECTION

    @Synchronized
    fun acquire(): Token {
        val nextGeneration = if (
            observedConnectionType == CarConnection.CONNECTION_TYPE_PROJECTION &&
            !currentConnectionAttested
        ) generation + 1 else generation
        val next = Token(Any(), nextGeneration)
        tokens[next.identity] = next
        if (observedConnectionType == CarConnection.CONNECTION_TYPE_PROJECTION) {
            attestCurrentProjectionLocked()
        }
        return next
    }

    @Synchronized
    fun release(candidate: Token) {
        val current = tokens[candidate.identity] ?: return
        if (current !== candidate) return
        tokens.remove(candidate.identity)
        // Session destruction can be a transient AA host unbind while the
        // same physical projection remains connected. The connection guard,
        // not the final UI Session token, retires continuity.
    }

    @Synchronized
    fun releaseAll() {
        tokens.clear()
        if (!currentConnectionAttested) return
        currentConnectionAttested = false
        sink?.onChanged(Snapshot(active = false, generation = generation))
    }

    @Synchronized
    internal fun onConnectionTypeChanged(type: Int) {
        observedConnectionType = type
        if (type == CarConnection.CONNECTION_TYPE_PROJECTION) {
            if (tokens.isNotEmpty()) attestCurrentProjectionLocked()
        } else {
            releaseAll()
        }
    }

    private fun attestCurrentProjectionLocked() {
        if (!currentConnectionAttested) {
            generation++
            currentConnectionAttested = true
        }
        sink?.onChanged(Snapshot(active = true, generation = generation))
    }

    @Synchronized
    fun current(): Snapshot = Snapshot(active = currentConnectionAttested, generation = generation)

    @Synchronized
    fun installSink(next: Sink?) {
        sink = next
        next?.onChanged(current())
    }
}

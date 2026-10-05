package com.cbstudio.telltale.car.health

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Repository exposing the latest [CarAlertSnapshot] as a StateFlow and semantic transitions (AA-05).
 */
class CarAlertRepository {
    private val _snapshot = MutableStateFlow(CarAlertSnapshot.INITIAL)
    val snapshot: StateFlow<CarAlertSnapshot> = _snapshot.asStateFlow()

    private val _transitions = MutableSharedFlow<CarAlertTransition>(extraBufferCapacity = 16)
    val transitions: SharedFlow<CarAlertTransition> = _transitions.asSharedFlow()

    fun updateSnapshot(newSnapshot: CarAlertSnapshot) {
        val old = _snapshot.value
        _snapshot.value = newSnapshot
        if (isSemanticAlertEdge(old.coolant, newSnapshot.coolant)) {
            _transitions.tryEmit(CarAlertTransition(old, newSnapshot))
        }
    }

    fun reset() {
        val old = _snapshot.value
        _snapshot.value = CarAlertSnapshot.INITIAL
        if (isSemanticAlertEdge(old.coolant, CarAlertSnapshot.INITIAL.coolant)) {
            _transitions.tryEmit(CarAlertTransition(old, CarAlertSnapshot.INITIAL))
        }
    }
}

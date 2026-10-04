package com.cbstudio.telltale.car.telemetry

/**
 * One projected signal.
 *
 * Invariant (enforced by construction): [value] is non-null if and only if
 * [status] is [CarSignalStatus.LIVE]. Instances are only obtainable through
 * [sanitize] and the constants below, so a stale/unsupported/unavailable value
 * can never carry a number into the car UI.
 */
class CarSignalValue private constructor(
    val status: CarSignalStatus,
    val value: Double?,
) {
    override fun equals(other: Any?): Boolean =
        other is CarSignalValue && other.status == status && other.value == value

    override fun hashCode(): Int = 31 * status.hashCode() + (value?.hashCode() ?: 0)

    override fun toString(): String = "CarSignalValue($status, $value)"

    companion object {
        val STALE = CarSignalValue(CarSignalStatus.STALE, null)
        val UNSUPPORTED = CarSignalValue(CarSignalStatus.UNSUPPORTED, null)
        val UNAVAILABLE = CarSignalValue(CarSignalStatus.UNAVAILABLE, null)

        /**
         * Applies the transport envelope to an incoming signal.
         *
         * - A non-live status always drops whatever number came with it.
         * - A live status without a finite number inside [envelope] becomes
         *   [UNAVAILABLE]: one corrupt signal is sanitized on its own and never
         *   rejects the rest of the frame.
         *
         * The envelope is a transport-corruption guard, not a statement about
         * what a healthy vehicle reports.
         */
        fun sanitize(
            status: CarSignalStatus,
            value: Double?,
            envelope: ClosedFloatingPointRange<Double>,
        ): CarSignalValue =
            when (status) {
                CarSignalStatus.LIVE ->
                    if (value != null && value.isFinite() && value in envelope) {
                        CarSignalValue(CarSignalStatus.LIVE, value)
                    } else {
                        UNAVAILABLE
                    }
                CarSignalStatus.STALE -> STALE
                CarSignalStatus.UNSUPPORTED -> UNSUPPORTED
                CarSignalStatus.UNAVAILABLE -> UNAVAILABLE
            }
    }
}

package com.cbstudio.telltale.car.hardware

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class CarHostSpeedRepositoryTest {

    private lateinit var repository: CarHostSpeedRepository

    @Before
    fun setUp() {
        repository = CarHostSpeedRepository(maxAgeMs = 3_000L)
    }

    @Test
    fun initialStateIsUnavailableWithNullSpeeds() {
        val sample = repository.sample.value
        assertEquals(CarHostSpeedStatus.UNAVAILABLE, sample.status)
        assertNull(sample.rawMetersPerSecond)
        assertNull(sample.displaySpeedMetersPerSecond)
    }

    @Test
    fun updateSampleUpdatesStateFlow() {
        val sample = CarHostSpeedSample(
            status = CarHostSpeedStatus.LIVE,
            rawMetersPerSecond = 10f,
            displaySpeedMetersPerSecond = 10.5f,
            receivedAtElapsedMs = 1_000L,
        )
        repository.updateSample(sample)

        assertEquals(sample, repository.sample.value)
    }

    @Test
    fun checkFreshnessKeepsLiveStatusWhenWithinMaxAge() {
        repository.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 10f,
                displaySpeedMetersPerSecond = 10.5f,
                receivedAtElapsedMs = 1_000L,
            ),
        )

        repository.checkFreshness(elapsedRealtimeMs = 3_500L) // 2500ms elapsed < 3000ms
        val current = repository.sample.value
        assertEquals(CarHostSpeedStatus.LIVE, current.status)
        assertEquals(10f, current.rawMetersPerSecond)
        assertEquals(10.5f, current.displaySpeedMetersPerSecond)
    }

    @Test
    fun checkFreshnessTransitionsToStaleAndClearsSpeedsWhenExpired() {
        repository.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 10f,
                displaySpeedMetersPerSecond = 10.5f,
                receivedAtElapsedMs = 1_000L,
            ),
        )

        repository.checkFreshness(elapsedRealtimeMs = 4_001L) // 3001ms elapsed > 3000ms
        val current = repository.sample.value
        assertEquals(CarHostSpeedStatus.STALE, current.status)
        assertNull(current.rawMetersPerSecond)
        assertNull(current.displaySpeedMetersPerSecond)
    }

    @Test
    fun checkFreshnessDoesNotModifyNonLiveSamples() {
        repository.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.PERMISSION_DENIED,
                receivedAtElapsedMs = 1_000L,
            ),
        )

        repository.checkFreshness(elapsedRealtimeMs = 10_000L)
        assertEquals(CarHostSpeedStatus.PERMISSION_DENIED, repository.sample.value.status)
    }

    @Test
    fun resetRestoresInitialSample() {
        repository.updateSample(
            CarHostSpeedSample(
                status = CarHostSpeedStatus.LIVE,
                rawMetersPerSecond = 10f,
                displaySpeedMetersPerSecond = 10.5f,
                receivedAtElapsedMs = 1_000L,
            ),
        )

        repository.reset()
        assertEquals(CarHostSpeedSample.INITIAL, repository.sample.value)
    }
}

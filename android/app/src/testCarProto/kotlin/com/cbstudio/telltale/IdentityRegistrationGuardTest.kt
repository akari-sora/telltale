package com.cbstudio.telltale

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class IdentityRegistrationGuardTest {
    @Test
    fun `activity recreation does not reattach the same producer engine`() {
        val guard = IdentityRegistrationGuard()
        val retainedEngine = Any()

        assertTrue(guard.admit(retainedEngine))
        assertFalse(guard.admit(retainedEngine))
        assertTrue(guard.admit(Any()))
    }
}

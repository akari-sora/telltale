package com.cbstudio.telltale

import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class ProjectionEngineOwnerTest {
    @Test
    fun `cold car bootstrap and warm activity share exactly one engine`() {
        val owner = ProjectionEngineOwner<Any>()
        val coldEngine = Any()

        assertTrue(owner.adopt(coldEngine))
        assertSame(coldEngine, owner.current())
        assertFalse("warm Activity registration must not duplicate setup", owner.adopt(coldEngine))
        assertSame(coldEngine, owner.current())
    }

    @Test(expected = IllegalStateException::class)
    fun `different engine cannot replace live projected engine`() {
        val owner = ProjectionEngineOwner<Any>()
        owner.adopt(Any())

        owner.adopt(Any())
    }

    @Test
    fun `only exact owner can clear the engine`() {
        val owner = ProjectionEngineOwner<Any>()
        val engine = Any()
        owner.adopt(engine)

        assertFalse(owner.clearIf(Any()))
        assertSame(engine, owner.current())
        assertTrue(owner.clearIf(engine))
    }
}

package com.cbstudio.telltale

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AppLocalePolicyTest {
    private val shippedIds = linkedMapOf(
        "en" to "en", "zh_Hant" to "zh-Hant", "de" to "de", "ja" to "ja",
        "ko" to "ko", "es" to "es", "fr" to "fr", "pt" to "pt-BR",
        "zh_Hans" to "zh-Hans", "it" to "it", "nl" to "nl",
    )

    @Test
    fun `API 33 is the LocaleManager floor`() {
        assertEquals(33, AppLocalePolicy.MIN_API)
        assertFalse(AppLocalePolicy.apiSupported(32))
        assertTrue(AppLocalePolicy.apiSupported(33))
        assertTrue(AppLocalePolicy.apiSupported(36))
    }

    @Test
    fun `supported tags are the shipped UI locales, not every ARB filename`() {
        assertEquals(shippedIds.values.toList(), AppLocalePolicy.supportedTags)
    }

    @Test
    fun `an empty request is follow-system, not English`() {
        val override = AppLocalePolicy.overrideFromRequestedTags(emptyList())
        assertEquals(AppLocaleOverride(followsSystem = true, tags = emptyList()), override)
    }

    @Test
    fun `a shipped tag becomes an explicit override`() {
        assertEquals(
            AppLocaleOverride(followsSystem = false, tags = listOf("zh-Hant")),
            AppLocalePolicy.overrideFromRequestedTags(listOf("zh-Hant")),
        )
        assertEquals(
            AppLocaleOverride(followsSystem = false, tags = listOf("en")),
            AppLocalePolicy.overrideFromRequestedTags(listOf("en-US")),
        )
        assertEquals(
            AppLocaleOverride(followsSystem = false, tags = listOf("de")),
            AppLocalePolicy.overrideFromRequestedTags(listOf("de-AT")),
        )
    }

    @Test
    fun `an unknown request is rejected rather than stored as a pretend locale`() {
        assertNull(AppLocalePolicy.overrideFromRequestedTags(listOf("sv")))
        assertNull(AppLocalePolicy.overrideFromRequestedTags(listOf("zh-US")))
        assertNull(AppLocalePolicy.overrideFromRequestedTags(listOf("en", "sv")))
    }

    @Test
    fun `an empty LocaleManager list is follow-system`() {
        val override = AppLocalePolicy.overrideFromLocaleListTags(emptyList())
        assertTrue(override.followsSystem)
        assertTrue(override.tags.isEmpty())
    }

    @Test
    fun `a nonempty LocaleManager list is an override even when we do not ship it`() {
        val override = AppLocalePolicy.overrideFromLocaleListTags(listOf("sv-SE"))
        assertFalse(override.followsSystem)
        assertEquals(listOf("sv-SE"), override.tags)
    }

    @Test
    fun `Locale getDefault is not consulted and cannot invent a system list`() {
        // The policy has no default-locale parameter. Passing configuration
        // tags as if they were the override is the defect this guards.
        val configuration = listOf("en-US")
        val override = AppLocalePolicy.overrideFromLocaleListTags(emptyList())
        assertTrue(override.followsSystem)
        assertFalse(override.tags == configuration)
    }

    @Test
    fun `language-tag string for LocaleList is empty when following system`() {
        assertEquals(
            "",
            AppLocalePolicy.languageTagsForLocaleList(
                AppLocaleOverride(followsSystem = true, tags = emptyList()),
            ),
        )
        assertEquals(
            "zh-Hant",
            AppLocalePolicy.languageTagsForLocaleList(
                AppLocaleOverride(followsSystem = false, tags = listOf("zh-Hant")),
            ),
        )
    }

    @Test
    fun `stored ids map to BCP47 tags the way Dart writes them`() {
        assertEquals(emptyList<String>(), AppLocalePolicy.tagsFromStoredId("system"))
        assertEquals(emptyList<String>(), AppLocalePolicy.tagsFromStoredId("nope"))
        for ((id, tag) in shippedIds) {
            assertEquals(listOf(tag), AppLocalePolicy.tagsFromStoredId(id))
            assertEquals(id, AppLocalePolicy.storedIdFromSupportedTag(tag))
            assertEquals(AppLocaleOverride(false, listOf(tag)), AppLocalePolicy.overrideFromRequestedTags(listOf(tag)))
            val migration = AppLocalePolicy.migrate(emptyList(), id)
            assertEquals(AppLocalePolicy.MigrationAction.HANDOFF_STORED_ONCE, migration.action)
            assertEquals(listOf(tag), migration.tagsToApply)
            assertEquals(id, migration.storedIdToKeep)
            assertTrue(migration.writeToOs)
        }
        assertEquals("system", AppLocalePolicy.storedIdFromSupportedTag("sv"))
    }

    @Test
    fun `regional tags and Chinese scripts map to shipped locales`() {
        val mappings = mapOf(
            "ja-JP" to "ja", "ko-KR" to "ko", "es-MX" to "es", "fr-CA" to "fr",
            "it-CH" to "it", "nl-BE" to "nl", "pt" to "pt-BR", "pt-PT" to "pt-BR",
            "pt-BR" to "pt-BR", "zh" to "zh-Hant", "zh-CN" to "zh-Hans",
            "zh-SG" to "zh-Hans", "zh-TW" to "zh-Hant", "zh-HK" to "zh-Hant",
            "zh-MO" to "zh-Hant", "zh_Hans_TW" to "zh-Hans", "zh-Hant-CN" to "zh-Hant",
        )
        for ((input, expected) in mappings) {
            assertEquals(input, expected, AppLocalePolicy.mapToSupported(input))
        }
        assertEquals(
            AppLocaleOverride(false, listOf("pt-BR", "zh-Hans")),
            AppLocalePolicy.overrideFromRequestedTags(listOf("pt-PT", "pt-BR", "zh-Hans-TW")),
        )
    }

    @Test
    fun `new OS locale overrides remain authoritative without rewriting`() {
        for ((tag, id) in mapOf("pt-PT" to "pt", "zh-Hans-TW" to "zh_Hans")) {
            val migration = AppLocalePolicy.migrate(listOf(tag), "en")
            assertEquals(AppLocalePolicy.MigrationAction.USE_OS_OVERRIDE, migration.action)
            assertEquals(listOf(tag), migration.tagsToApply)
            assertEquals(id, migration.storedIdToKeep)
            assertFalse(migration.writeToOs)
        }
    }

    @Test
    fun `OS explicit selection wins and is not overwritten by the stored id`() {
        val m = AppLocalePolicy.migrate(
            osOverrideTags = listOf("de-DE"),
            storedId = "en",
        )
        assertEquals(AppLocalePolicy.MigrationAction.USE_OS_OVERRIDE, m.action)
        assertFalse(m.writeToOs)
        assertEquals("de", m.storedIdToKeep)
    }

    @Test
    fun `an empty OS list hands off a stored explicit preference once`() {
        val m = AppLocalePolicy.migrate(
            osOverrideTags = emptyList(),
            storedId = "zh_Hant",
        )
        assertEquals(AppLocalePolicy.MigrationAction.HANDOFF_STORED_ONCE, m.action)
        assertTrue(m.writeToOs)
        assertEquals(listOf("zh-Hant"), m.tagsToApply)
        assertEquals("zh_Hant", m.storedIdToKeep)
    }

    @Test
    fun `both empty stays on system and writes nothing`() {
        val m = AppLocalePolicy.migrate(
            osOverrideTags = emptyList(),
            storedId = "system",
        )
        assertEquals(AppLocalePolicy.MigrationAction.FOLLOW_SYSTEM, m.action)
        assertFalse(m.writeToOs)
        assertTrue(m.tagsToApply.isEmpty())
        assertEquals("system", m.storedIdToKeep)
    }

    @Test
    fun `an OS override we do not ship still wins and does not take the stored id`() {
        val m = AppLocalePolicy.migrate(
            osOverrideTags = listOf("sv"),
            storedId = "en",
        )
        assertEquals(AppLocalePolicy.MigrationAction.USE_OS_OVERRIDE, m.action)
        assertFalse(m.writeToOs)
        assertEquals("system", m.storedIdToKeep)
    }
}

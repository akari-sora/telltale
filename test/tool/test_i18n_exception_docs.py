"""Guard the documented Torque exceptions and repository references."""

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class I18nExceptionDocsTest(unittest.TestCase):
    def test_torque_exception_table_matches_shipped_arbs(self):
        locales = tuple(sorted(path.stem.removeprefix("app_") for path in
                               (ROOT / "lib/l10n").glob("app_*.arb")
                               if path.stem != "app_en"))
        keys = ("derivedTorque", "dtcDescriptionP0740", "dtcDescriptionP0741")
        readme = (ROOT / "docs/i18n/README.md").read_text(encoding="utf-8")
        arbs = {
            locale: json.loads((ROOT / f"lib/l10n/app_{locale}.arb").read_text(encoding="utf-8"))
            for locale in locales
        }
        for key in keys:
            with self.subTest(key=key):
                # An exception is needed when the protected spelling from
                # the English source is absent (including case changes).
                expected = {locale for locale in locales if "Torque" not in arbs[locale][key]}
                match = re.search(rf"^\| `{key}` \| ([^|]+) \|$", readme, re.MULTILINE)
                self.assertIsNotNone(match, f"Missing exception table row for {key}")
                actual = set(re.findall(r"`([^`]+)`", match.group(1)))
                self.assertEqual(actual, expected)

    def test_parity_comments_reference_repository_contract(self):
        parity = (ROOT / "test/l10n/arb_parity_test.dart").read_text(encoding="utf-8")
        self.assertNotIn("inputs/docs/do-not-translate.md", parity)
        for token in ("BEV", "PHEV"):
            self.assertIn(f"{token} in docs/i18n/do-not-translate.md", parity)


if __name__ == "__main__":
    unittest.main()

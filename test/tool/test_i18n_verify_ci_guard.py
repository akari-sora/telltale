#!/usr/bin/env python3
"""#47: CI must run the ARB locale checker, not only ship the files.

Drives the text of `.github/workflows/ci.yml`, not a rewrite of the checker.
"""

from __future__ import annotations

import json
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CI_PATH = REPO / ".github" / "workflows" / "ci.yml"
ARB_DIR = REPO / "lib" / "l10n"


class I18nVerifyCiGuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = CI_PATH.read_text(encoding="utf-8")

    def test_ci_discovers_the_i18n_verify_unittests(self) -> None:
        self.assertIn("-s tool/i18n_verify", self.workflow)
        self.assertIn("python3 -m unittest discover", self.workflow)
        self.assertIn("tool/i18n_verify/check_arb.py", self.workflow)

    def test_ci_runs_check_arb_on_shipped_locales(self) -> None:
        shipped = sorted(path.name for path in ARB_DIR.glob("*.arb"))
        self.assertIn("app_en.arb", shipped)
        # Read from the directory rather than a list written here. A new locale
        # is a file somebody adds; the guard has to notice the file, not a
        # second list they also had to remember to edit.
        for name in shipped:
            self.assertIn(
                f"lib/l10n/{name}",
                self.workflow,
                msg=f"{name} ships but CI never checks its keys",
            )
        arb_step = self.workflow.index("ARB locales have matching keys")
        shipped = self.workflow.index("lib/l10n/app_en.arb")
        self.assertGreater(shipped, arb_step)

    def test_portable_gate_checks_every_arb(self) -> None:
        gate = (REPO / "tool/ci/full_gate.sh").read_text(encoding="utf-8")
        self.assertIn("run_step arb-locales python3 tool/i18n_verify/check_arb.py", gate)
        arb_step = gate[gate.index("run_step arb-locales"):gate.index("run_step analyze")]
        self.assertLess(arb_step.index("app_en.arb"), arb_step.index("app_de.arb"))
        for path in ARB_DIR.glob("*.arb"):
            self.assertIn(f"lib/l10n/{path.name}", arb_step)

    def test_acceptance_manifest_lists_configured_locales(self) -> None:
        manifest = json.loads(
            (REPO / "tool/i18n_verify/production_acceptance_manifest.json").read_text()
        )
        config = ET.parse(REPO / "android/app/src/main/res/xml/locales_config.xml")
        tags = [node.attrib["{http://schemas.android.com/apk/res/android}name"]
                for node in config.getroot()]
        self.assertEqual(manifest["supportedAppLocales"], tags)
        residual = next(item for item in manifest["nativeResiduals"]
                        if item["residualId"] == "R04_ADDITIONAL_LOCALE_ACCEPTANCE")
        self.assertEqual(residual["status"], "NOT_RUN")

    def test_ci_compiles_the_checker_before_running_it(self) -> None:
        compile_at = self.workflow.index(
            "python3 -m py_compile tool/i18n_verify/check_arb.py"
        )
        discover_at = self.workflow.index("-s tool/i18n_verify")
        self.assertGreater(discover_at, compile_at)


if __name__ == "__main__":
    unittest.main()

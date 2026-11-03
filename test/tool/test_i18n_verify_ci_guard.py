#!/usr/bin/env python3
"""#47: CI must run the ARB locale checker, not only ship the files.

Drives the text of `.github/workflows/ci.yml`, not a rewrite of the checker.
"""

from __future__ import annotations

import json
import shlex
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

    def _check_arb_arguments(self, script: str) -> list[str]:
        # Join shell continuations before tokenizing so only arguments belonging
        # to the actual checker invocation count, not text elsewhere in CI.
        lines = script.replace("\\\n", " ").splitlines()
        commands = []
        checker = "tool/i18n_verify/check_arb.py"
        for line in lines:
            if checker not in line or line.lstrip().startswith("#"):
                continue
            tokens = shlex.split(line.strip(), comments=True)
            if checker in tokens and tokens.index(checker) > 0:
                index = tokens.index(checker)
                if tokens[index - 1] == "python3":
                    commands.append(tokens[index + 1:])
        self.assertEqual(len(commands), 1, "expected one check_arb invocation")
        return commands[0]

    def _assert_shipped_arb_command(self, args: list[str]) -> None:
        self.assertTrue(args, "check_arb must receive ARB arguments")
        self.assertEqual(args[0], "lib/l10n/app_en.arb")
        shipped = [f"lib/l10n/{path.name}" for path in ARB_DIR.glob("*.arb")]
        self.assertIn("lib/l10n/app_en.arb", shipped)
        self.assertCountEqual(args, shipped, "one command must check every shipped ARB")

    def test_ci_runs_check_arb_on_shipped_locales(self) -> None:
        self._assert_shipped_arb_command(self._check_arb_arguments(self.workflow))

    def test_portable_gate_checks_every_arb(self) -> None:
        gitlab = (REPO / ".gitlab-ci.yml").read_text(encoding="utf-8")
        self.assertIn("bash tool/ci/full_gate.sh", gitlab)
        gate = (REPO / "tool/ci/full_gate.sh").read_text(encoding="utf-8")
        self._assert_shipped_arb_command(self._check_arb_arguments(gate))

    def test_swapped_english_and_chinese_are_rejected(self) -> None:
        gate = (REPO / "tool/ci/full_gate.sh").read_text(encoding="utf-8")
        for name, script in (("GitHub", self.workflow), ("GitLab", gate)):
            with self.subTest(script=name):
                en, zh = "lib/l10n/app_en.arb", "lib/l10n/app_zh.arb"
                swapped = script.replace(en, "__ARB_SWAP__", 1).replace(zh, en, 1)
                swapped = swapped.replace("__ARB_SWAP__", zh, 1)
                with self.assertRaises(AssertionError):
                    self._assert_shipped_arb_command(self._check_arb_arguments(swapped))

    def test_arb_mentioned_outside_the_command_does_not_count(self) -> None:
        missing = self.workflow.replace("lib/l10n/app_zh.arb", "", 1)
        missing += "\n echo lib/l10n/app_zh.arb\n"
        with self.assertRaises(AssertionError):
            self._assert_shipped_arb_command(self._check_arb_arguments(missing))

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

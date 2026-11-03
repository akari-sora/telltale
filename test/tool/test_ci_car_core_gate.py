"""Exercise car-core report collection in the actual CI gate script."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CarCoreGateTest(unittest.TestCase):
    def run_gate(self, gradle_exit, reports=True, fail_copy=False, existing_reports=False):
        temp = tempfile.TemporaryDirectory(prefix="car-core-gate-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        (root / "android").mkdir()
        (root / "bin").mkdir()
        gradlew = root / "android/gradlew"
        gradlew.write_text(f"#!/bin/sh\nprintf 'gradle output\\n'\nexit {gradle_exit}\n")
        gradlew.chmod(0o755)
        for report, content in (
            ("test-results/testDebugUnitTest/TEST-example.xml", "<testsuite/>"),
            ("reports/tests/testDebugUnitTest/index.html", "<html/>"),
        ):
            if reports:
                path = root / "build/car-core" / report
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
        if existing_reports:
            for report in ("test-results/testDebugUnitTest/TEST-example.xml", "reports/tests/testDebugUnitTest/index.html"):
                path = root / "ci-artifacts/car-core" / report
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("old report")
        if fail_copy:
            cp = root / "bin/cp"
            cp.write_text("#!/bin/sh\nexit 23\n")
            cp.chmod(0o755)
        gate = (ROOT / "tool/ci/full_gate.sh").read_text()
        prelude = gate[: gate.index("run_step source ")]
        block = gate[gate.index("car_core_rc=0") : gate.index("run_step car-field-unit")]
        env = os.environ.copy()
        env["PATH"] = f"{root / 'bin'}{os.pathsep}{env['PATH']}"
        result = subprocess.run(["bash", "-c", prelude + block], cwd=root, env=env, capture_output=True, text=True)
        artifacts = root / "ci-artifacts"
        self.assertEqual((artifacts / "car-core-unit.exit").read_text().strip(), str(gradle_exit))
        self.assertEqual((artifacts / "car-core-unit.stdout").read_text().strip(), "gradle output")
        if reports and not fail_copy:
            self.assertEqual((artifacts / "car-core/test-results/testDebugUnitTest/TEST-example.xml").read_text(), "<testsuite/>")
            self.assertEqual((artifacts / "car-core/reports/tests/testDebugUnitTest/index.html").read_text(), "<html/>")
        return result

    def test_reports_preserved_on_success_and_failure(self):
        for code in (0, 7):
            with self.subTest(gradle_exit=code):
                self.assertEqual(self.run_gate(code).returncode, code)

    def test_existing_reports_are_updated_without_nesting(self):
        self.assertEqual(self.run_gate(0, existing_reports=True).returncode, 0)

    def test_missing_reports_do_not_change_gradle_exit(self):
        for code in (0, 7):
            with self.subTest(gradle_exit=code):
                self.assertEqual(self.run_gate(code, reports=False).returncode, code)

    def test_report_copy_failure_preserves_gradle_failure_or_fails_success(self):
        self.assertEqual(self.run_gate(7, fail_copy=True).returncode, 7)
        self.assertEqual(self.run_gate(0, fail_copy=True).returncode, 23)


if __name__ == "__main__":
    unittest.main()

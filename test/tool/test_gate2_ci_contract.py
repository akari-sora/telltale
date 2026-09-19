"""Host orchestration/metadata tests; these do not qualify an APK or Android."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('mode08_ci', ROOT / 'tool/ci/run_mode08_required.py')
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)


class RequiredRunnerTests(unittest.TestCase):
    def test_actual_announced_ephemeral_port(self):
        self.assertEqual(ci.ready_port('Mode 08 replay reference listening on 127.0.0.1:41877 (hash: abc123)\n'), 41877)

    def test_no_zero_or_out_of_range_port(self):
        for port in (0, 65536):
            self.assertIsNone(ci.ready_port(f'Mode 08 replay reference listening on 127.0.0.1:{port} (hash: abc123)'))

    def test_no_external_host(self):
        self.assertIsNone(ci.ready_port('Mode 08 replay reference listening on 0.0.0.0:1234 (hash: abc123)'))

    def test_no_inexact_identity(self):
        self.assertIsNone(ci.ready_port('other server listening on 127.0.0.1:1234 (hash: abc123)'))

    def test_preserves_real_nonzero_child_exit(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            rc = ci.checked_run([sys.executable, '-c', 'raise SystemExit(7)'], root,
                                root / 'out', root / 'err', 5)
            self.assertEqual(rc, 7)

    def test_preserves_real_stdout_and_stderr(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            rc = ci.checked_run([sys.executable, '-c', 'import sys; print("out"); print("err", file=sys.stderr)'],
                                root, root / 'out', root / 'err', 5)
            self.assertEqual(rc, 0)
            self.assertEqual((root / 'out').read_text(), 'out\n')
            self.assertEqual((root / 'err').read_text(), 'err\n')

    def test_timeout_is_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            with self.assertRaises(subprocess.TimeoutExpired):
                ci.checked_run([sys.executable, '-c', 'import time; time.sleep(10)'],
                               root, root / 'out', root / 'err', 0.1)

    def test_cleanup_stops_owned_process(self):
        child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(10)'])
        self.assertTrue(ci.stop_owned(child))
        self.assertIsNotNone(child.poll())

    def test_cleanup_is_idempotent(self):
        self.assertTrue(ci.stop_owned(None))
        child = subprocess.Popen([sys.executable, '-c', 'pass'])
        child.wait(timeout=5)
        self.assertTrue(ci.stop_owned(child))

    def test_existing_evidence_directory_cannot_be_overwritten(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'original.txt').write_text('retain')
            with self.assertRaises(FileExistsError):
                ci.run(root, root, 'flutter', 5)
            self.assertEqual((root / 'original.txt').read_text(), 'retain')

    def test_host_test_cannot_export_synthetic_android_events(self):
        source = (ROOT / 'test/diagnostics/service_recipes/mode08_d05_supplement_test.dart').read_text()
        for forbidden in ['logEvent(', "recordTraffic(", 'candidate_apk_sha256',
                          'GENERATE_MODE08_EVIDENCE', 'writeAsString(', 'openWrite(']:
            self.assertNotIn(forbidden, source)
        self.assertIn("int.fromEnvironment('MODE08_ORACLE_PORT'", source)
        self.assertIn('Host-only', source)


if __name__ == '__main__':
    unittest.main()

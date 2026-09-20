#!/usr/bin/env python3
"""Host tests for D05 UI-dump readiness. No emulator and no APK launch."""
from __future__ import annotations

import asyncio
import importlib.util
import os
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
SPEC = importlib.util.spec_from_file_location(
    'd05_android_controller', ROOT / 'tool/verification/d05_android_controller.py'
)
CTRL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CTRL)

VALID_HIERARCHY = (
    b"<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n"
    b'<hierarchy rotation="0">'
    b'<node text="Discover Mode 08" content-desc="" bounds="[10,20][200,80]" '
    b'enabled="true" clickable="true" class="android.widget.Button"/>'
    b'</hierarchy>\n'
)
EMPTY_HIERARCHY = (
    b"<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n"
    b'<hierarchy rotation="0"/>\n'
)
XML_DECLARATION_ONLY = b"<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n"
NULL_ROOT_STDERR = 'ERROR: null root node returned by UiTestAutomationBridge.\n'


def _png():
    return b'\x89PNG\r\n\x1a\n' + b'not-a-full-png-but-enough-for-header'


class HierarchyParseTests(unittest.TestCase):
    def test_valid_dump_keeps_labeled_nodes(self):
        rows = CTRL.parse_ui_rows(VALID_HIERARCHY)
        self.assertEqual(rows[0]['text'], 'Discover Mode 08')
        self.assertEqual(rows[0]['clazz'], 'android.widget.Button')

    def test_empty_file_is_not_a_hierarchy(self):
        with self.assertRaisesRegex(ValueError, 'empty'):
            CTRL.parse_ui_rows(b'')

    def test_xml_declaration_without_root_is_unusable(self):
        with self.assertRaises(ET.ParseError):
            CTRL.parse_ui_rows(XML_DECLARATION_ONLY)

    def test_empty_hierarchy_is_unusable(self):
        with self.assertRaisesRegex(ValueError, 'no nodes'):
            CTRL.parse_ui_rows(EMPTY_HIERARCHY)

    def test_missing_xml_marker_is_unusable(self):
        with self.assertRaisesRegex(ValueError, 'no XML hierarchy'):
            CTRL.parse_ui_rows(b'not xml\n')


class ResumeDetectionTests(unittest.TestCase):
    def test_top_resumed_activity_counts(self):
        text = '  topResumedActivity=ActivityRecord{abc u0 com.cbstudio.telltale/.MainActivity t3}'
        self.assertTrue(CTRL.activity_is_resumed(text))

    def test_focused_app_counts(self):
        text = '  mFocusedApp=AppWindowToken{x token=ActivityRecord{y u0 com.cbstudio.telltale/.MainActivity t3}}'
        self.assertTrue(CTRL.activity_is_resumed(text))

    def test_other_package_does_not_count(self):
        text = '  mResumedActivity: ActivityRecord{abc u0 com.android.systemui/.keyguard.KeyguardService t1}'
        self.assertFalse(CTRL.activity_is_resumed(text))

    def test_same_package_without_resume_marker_does_not_count(self):
        text = '    Hist  #0: ActivityRecord{abc u0 com.cbstudio.telltale/.MainActivity t3}'
        self.assertFalse(CTRL.activity_is_resumed(text))


class DumpRetryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.calls = []
        CTRL.WAKE_KEYEVENT_DISABLED = False

    def _run(self, coro):
        return asyncio.run(coro)

    def _patch_out(self):
        return patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.out / 'controller.jsonl',
                              DUMP_READY_SECONDS=20, DUMP_RETRY_SLEEP=0)

    def test_dump_retries_after_null_root_then_accepts_hierarchy(self):
        responses = [
            (b'', NULL_ROOT_STDERR, 0),
            (VALID_HIERARCHY, 'UI hierchary dumped to: /sdcard/d05_window.xml\n', 0),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('shell', 'rm', '-f'):
                return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''
            if args[:2] == ('shell', 'uiautomator'):
                stdout, stderr, code = responses[0] if len([c for c in self.calls if c[:2] == ('shell', 'uiautomator')]) == 1 else responses[1]
                result = SimpleNamespace(returncode=code, stdout=stdout, stderr=stderr.encode())
                return result if full else stdout
            if args[:3] == ('exec-out', 'cat', CTRL.REMOTE_DUMP):
                dumps = [c for c in self.calls if c[:2] == ('shell', 'uiautomator')]
                stdout = responses[0][0] if len(dumps) == 1 else responses[1][0]
                return stdout
            if args[:2] in (('shell', 'input'), ('shell', 'wm'), ('shell', 'svc')):
                result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
                return result if full else b''
            raise AssertionError('unexpected adb args: ' + repr(args))

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            rows = self._run(CTRL.dump('initial', screenshot=False))
        self.assertEqual(rows[0]['text'], 'Discover Mode 08')
        self.assertTrue(any(path.name.endswith('_unusable_1.xml') for path in self.out.glob('*_unusable_1.xml')))
        self.assertGreaterEqual(len([c for c in self.calls if c[:2] == ('shell', 'uiautomator')]), 2)

    def test_dump_fails_closed_when_hierarchy_never_arrives(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            if args[:2] == ('shell', 'uiautomator'):
                result = SimpleNamespace(returncode=0, stdout=b'', stderr=NULL_ROOT_STDERR.encode())
                return result if full else b''
            if args[:2] == ('exec-out', 'cat'):
                return XML_DECLARATION_ONLY
            return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL, 'DUMP_READY_SECONDS', 0), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            with self.assertRaisesRegex(RuntimeError, 'stayed empty'):
                self._run(CTRL.dump('initial', screenshot=False))

    def test_launch_app_waits_until_main_activity_resumes(self):
        dumpsys = [
            b'  mResumedActivity: ActivityRecord{abc u0 com.android.systemui/.keyguard.KeyguardService t1}\n',
            b'  topResumedActivity=ActivityRecord{def u0 com.cbstudio.telltale/.MainActivity t2}\n',
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('shell', 'dumpsys', 'activity'):
                data = dumpsys.pop(0)
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            self._run(CTRL.launch_app())
        self.assertTrue(any(c[:4] == ('shell', 'am', 'start', '-n') for c in self.calls))
        self.assertEqual(len([c for c in self.calls if c[:3] == ('shell', 'dumpsys', 'activity')]), 2)


class WakeTimeoutTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.calls = []
        CTRL.WAKE_KEYEVENT_DISABLED = False

    def _run(self, coro):
        return asyncio.run(coro)

    def _patch_out(self):
        return patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.out / 'controller.jsonl')

    def test_check_false_swallows_timeout_expired(self):
        def boom(*_args, **_kwargs):
            raise subprocess.TimeoutExpired(cmd=['adb', 'shell', 'input', 'keyevent', '224'], timeout=8)

        with self._patch_out(), patch.object(CTRL.subprocess, 'run', boom):
            result = self._run(CTRL.adb('shell', 'input', 'keyevent', '224', timeout=8, check=False))
        self.assertEqual(result, b'')

    def test_check_false_full_marks_timeout_returncode(self):
        def boom(*_args, **_kwargs):
            raise subprocess.TimeoutExpired(cmd=['adb'], timeout=8)

        with self._patch_out(), patch.object(CTRL.subprocess, 'run', boom):
            result = self._run(CTRL.adb('shell', 'input', 'keyevent', '224', timeout=8, check=False, full=True))
        self.assertEqual(result.returncode, -1)

    def test_check_true_still_raises_timeout_expired(self):
        def boom(*_args, **_kwargs):
            raise subprocess.TimeoutExpired(cmd=['adb', 'shell', 'input', 'keyevent', '224'], timeout=8)

        with self._patch_out(), patch.object(CTRL.subprocess, 'run', boom):
            with self.assertRaises(subprocess.TimeoutExpired):
                self._run(CTRL.adb('shell', 'input', 'keyevent', '224', timeout=8, check=True))

    def test_wake_uses_power_and_dismisses_keyguard_after_keyevent_timeout(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('shell', 'input', 'keyevent'):
                result = SimpleNamespace(returncode=-1, stdout=b'', stderr=b'')
            else:
                result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else result.stdout

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb):
            self._run(CTRL.wake_and_unlock())
            self._run(CTRL.wake_and_unlock())
        self.assertTrue(any(c[:4] == ('shell', 'svc', 'power', 'stayon') for c in self.calls))
        self.assertTrue(any(c[:3] == ('shell', 'wm', 'dismiss-keyguard') for c in self.calls))
        self.assertEqual(len([c for c in self.calls if c[:3] == ('shell', 'input', 'keyevent')]), 1)
        self.assertTrue(CTRL.WAKE_KEYEVENT_DISABLED)

    def test_launch_app_starts_activity_after_wake_timeout(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('shell', 'dumpsys', 'activity'):
                data = b'  topResumedActivity=ActivityRecord{def u0 com.cbstudio.telltale/.MainActivity t2}\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            if args[:3] == ('shell', 'input', 'keyevent'):
                result = SimpleNamespace(returncode=-1, stdout=b'', stderr=b'')
                return result if full else b''
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb):
            self._run(CTRL.launch_app())
        self.assertTrue(any(c[:4] == ('shell', 'am', 'start', '-n') for c in self.calls))
        self.assertTrue(any(c[:3] == ('shell', 'wm', 'dismiss-keyguard') for c in self.calls))


if __name__ == '__main__':
    unittest.main()

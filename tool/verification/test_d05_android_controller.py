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
        with self.assertRaisesRegex(ValueError, 'truncated|no XML hierarchy'):
            CTRL.parse_ui_rows(XML_DECLARATION_ONLY)

    def test_empty_hierarchy_is_unusable(self):
        with self.assertRaisesRegex(ValueError, 'no nodes'):
            CTRL.parse_ui_rows(EMPTY_HIERARCHY)

    def test_missing_xml_marker_is_unusable(self):
        with self.assertRaisesRegex(ValueError, 'no XML hierarchy'):
            CTRL.parse_ui_rows(b'not xml\n')

    def test_trailing_uiautomator_tty_status_is_ignored(self):
        payload = VALID_HIERARCHY + b'UI hierchary dumped to: /dev/tty\n'
        rows = CTRL.parse_ui_rows(payload)
        self.assertEqual(rows[0]['text'], 'Discover Mode 08')
        self.assertEqual(CTRL.hierarchy_slice(payload), VALID_HIERARCHY.rstrip())

    def test_second_document_after_hierarchy_is_ignored(self):
        payload = VALID_HIERARCHY + b"<?xml version='1.0'?><hierarchy rotation='0'/>\n"
        rows = CTRL.parse_ui_rows(payload)
        self.assertEqual(rows[0]['text'], 'Discover Mode 08')

    def test_truncated_hierarchy_is_unusable(self):
        with self.assertRaisesRegex(ValueError, 'truncated'):
            CTRL.parse_ui_rows(b"<?xml version='1.0'?><hierarchy rotation='0'><node text='x'")


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

    def test_current_focus_counts(self):
        text = '  mCurrentFocus=Window{abc u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}'
        self.assertTrue(CTRL.window_is_focused(text))

    def test_keyguard_focus_does_not_count(self):
        text = '  mCurrentFocus=Window{abc u0 StatusBar}'
        self.assertFalse(CTRL.window_is_focused(text))


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
            (NULL_ROOT_STDERR.encode(), NULL_ROOT_STDERR, 0),
            (VALID_HIERARCHY, '', 0),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('exec-out', 'uiautomator', 'dump'):
                count = len([c for c in self.calls if c[:3] == ('exec-out', 'uiautomator', 'dump')])
                stdout, stderr, code = responses[0] if count == 1 else responses[1]
                result = SimpleNamespace(returncode=code, stdout=stdout, stderr=stderr.encode())
                return result if full else stdout
            if args[:3] == ('shell', 'input', 'keyevent'):
                raise AssertionError('dump retry must not spend budget on keyevent')
            if args[:3] == ('shell', 'dumpsys', 'window'):
                data = b'  mCurrentFocus=Window{abc u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            if args[:2] in (('shell', 'input'), ('shell', 'wm'), ('shell', 'svc'), ('shell', 'settings')):
                result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
                return result if full else b''
            if args[:1] == ('logcat',):
                data = b'ActivityTaskManager: Fully drawn com.cbstudio.telltale/.MainActivity: +1s\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            raise AssertionError('unexpected adb args: ' + repr(args))

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            rows = self._run(CTRL.dump('initial', screenshot=False))
        self.assertEqual(rows[0]['text'], 'Discover Mode 08')
        self.assertTrue(any(path.name.endswith('_unusable_1.xml') for path in self.out.glob('*_unusable_1.xml')))
        self.assertGreaterEqual(len([c for c in self.calls if c[:3] == ('exec-out', 'uiautomator', 'dump')]), 2)

    def test_dump_fails_closed_when_hierarchy_never_arrives(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            if args[:3] == ('exec-out', 'uiautomator', 'dump'):
                result = SimpleNamespace(returncode=0, stdout=NULL_ROOT_STDERR.encode(), stderr=NULL_ROOT_STDERR.encode())
                return result if full else NULL_ROOT_STDERR.encode()
            if args[:2] == ('shell', 'dumpsys'):
                data = b'  mCurrentFocus=Window{abc u0 StatusBar}\n  mWakefulness=Awake\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            if args[:1] == ('logcat',):
                data = b'E AndroidRuntime: FATAL EXCEPTION: main\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL, 'DUMP_READY_SECONDS', 0), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            with self.assertRaisesRegex(RuntimeError, 'stayed empty.*crashes='):
                self._run(CTRL.dump('initial', screenshot=False))
        self.assertTrue(any(path.name.endswith('_logcat.txt') for path in self.out.glob('*')))
        self.assertTrue(any('_raw.bin' in path.name for path in self.out.glob('*')))

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
            if args[:3] == ('shell', 'dumpsys', 'window'):
                data = b'  mCurrentFocus=Window{abc u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            if args[:1] == ('logcat',):
                data = b'ActivityTaskManager: Fully drawn com.cbstudio.telltale/.MainActivity: +1s\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            self._run(CTRL.launch_app())
        self.assertTrue(any(c[:3] == ('shell', 'am', 'start') for c in self.calls))
        self.assertTrue(any('-W' in c for c in self.calls if c[:3] == ('shell', 'am', 'start')))
        self.assertEqual(len([c for c in self.calls if c[:3] == ('shell', 'dumpsys', 'activity')]), 2)
        self.assertTrue(any(c[:4] == ('shell', 'settings', 'put', 'secure') for c in self.calls))
        self.assertTrue(any(c[:3] == ('shell', 'dumpsys', 'window') for c in self.calls))


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
            if args[:3] == ('shell', 'dumpsys', 'window'):
                data = b'  mCurrentFocus=Window{abc u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            if args[:3] == ('shell', 'input', 'keyevent'):
                result = SimpleNamespace(returncode=-1, stdout=b'', stderr=b'')
                return result if full else b''
            if args[:1] == ('logcat',):
                data = b'ActivityTaskManager: Fully drawn com.cbstudio.telltale/.MainActivity: +1s\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb):
            self._run(CTRL.launch_app())
        self.assertTrue(any(c[:3] == ('shell', 'am', 'start') for c in self.calls))
        self.assertTrue(any(c[:3] == ('shell', 'wm', 'dismiss-keyguard') for c in self.calls))
        self.assertTrue(any(c[:3] == ('shell', 'dumpsys', 'window') for c in self.calls))
        self.assertTrue(any(c[:1] == ('logcat',) for c in self.calls))


class DrawnWindowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.calls = []

    def _run(self, coro):
        return asyncio.run(coro)

    def _patch_out(self):
        return patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.out / 'controller.jsonl',
                              DRAWN_POLL_SLEEP=0)

    def test_wait_returns_on_fully_drawn_log(self):
        logs = [
            b'FlutterRenderer: Width is zero. 0,0\n',
            b'ActivityTaskManager: Fully drawn com.cbstudio.telltale/.MainActivity: +1m44s\n',
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:1] == ('logcat',):
                data = logs.pop(0)
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            raise AssertionError('unexpected adb args: ' + repr(args))

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            self._run(CTRL.wait_for_drawn_window(timeout=20))
        self.assertEqual(len([c for c in self.calls if c[:1] == ('logcat',)]), 2)

    def test_wait_does_not_raise_when_fully_drawn_never_arrives(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            data = b'FlutterRenderer: Width is zero. 0,0\n'
            return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep), \
                patch.object(CTRL, 'DRAWN_WAIT_SECONDS', 0):
            self._run(CTRL.wait_for_drawn_window(timeout=0))



class PrepareWindowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.calls = []

    def _run(self, coro):
        return asyncio.run(coro)

    def test_skips_lockscreen_swipe_when_app_already_focused(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('shell', 'dumpsys', 'window'):
                data = b'  mCurrentFocus=Window{abc u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}\n'
                return SimpleNamespace(returncode=0, stdout=data, stderr=b'') if full else data
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        with patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.out / 'controller.jsonl'), \
                patch.object(CTRL, 'adb', fake_adb):
            self._run(CTRL.prepare_window(unlock_swipe=True))
        self.assertFalse(any(c[:3] == ('shell', 'input', 'swipe') for c in self.calls))
        self.assertTrue(any(c[:3] == ('shell', 'dumpsys', 'window') for c in self.calls))



    def test_dump_does_not_lockscreen_swipe(self):
        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:2] == ('exec-out', 'uiautomator') or args[:2] == ('shell', 'uiautomator'):
                result = SimpleNamespace(returncode=0, stdout=VALID_HIERARCHY, stderr=b'')
                return result if full else VALID_HIERARCHY
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        with patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.out / 'controller.jsonl'), \
                patch.object(CTRL, 'adb', fake_adb):
            self._run(CTRL.dump('initial', screenshot=False))
        self.assertFalse(any(c[:3] == ('shell', 'input', 'swipe') for c in self.calls))


class TapTextMatchTests(unittest.TestCase):
    def test_settings_tab_matches_and_disclosure_does_not(self):
        tab = dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                   clickable='true', bounds='[384,684][480,752]')
        disclosure = dict(text='', desc='Full disclosure in Settings', enabled='true',
                          clickable='true', bounds='[16,672][217,720]')
        self.assertTrue(CTRL.node_matches(tab, 'Settings'))
        self.assertFalse(CTRL.node_matches(disclosure, 'Settings'))
        found = CTRL.locate_text([disclosure, tab], 'Settings')
        self.assertEqual(found[0]['desc'], 'Settings\nTab 5 of 5')

    def test_service_recipes_and_discover_use_first_line_prefix(self):
        recipes = dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                       clickable='true', bounds='[16,400][464,470]')
        discover = dict(text='', desc='Discover Mode 08 Supported TIDs', enabled='true',
                        clickable='true', bounds='[16,200][464,250]')
        self.assertTrue(CTRL.node_matches(recipes, 'Service Recipes'))
        self.assertTrue(CTRL.node_matches(discover, 'Discover Mode 08'))

    def test_tap_text_scrolls_until_the_row_appears(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dumps = [
            [dict(text='', desc='Wi-Fi\nA TCP port', enabled='true', clickable='true',
                  bounds='[16,398][464,473]')],
            [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                  clickable='true', bounds='[16,400][464,470]')],
        ]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl', TAP_SCROLL_ATTEMPTS=3), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        swipes = [c for c in calls if c[:3] == ('shell', 'input', 'swipe')]
        self.assertEqual(len(swipes), 3)
        self.assertEqual(swipes[0][3:8], (40, 620, 40, 90, 80))
        self.assertTrue(any(c[:3] == ('shell', 'input', 'tap') for c in calls))

    def test_settings_tab_waits_without_swiping_connect(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        connect = [
            dict(text='', desc='The adapter stopped responding and the connection has been dropped.',
                 enabled='true', clickable='false', bounds='[65,45][447,87]'),
            dict(text='', desc='Full disclosure in Settings', enabled='true',
                 clickable='true', bounds='[16,672][217,720]'),
            dict(text='', desc='Wi-Fi\nA TCP port, usually 192.168.0.10:35000',
                 enabled='true', clickable='true', bounds='[16,634][464,709]'),
        ]
        dashboard = connect + [
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        dumps = [connect, dashboard]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl', TAP_SCROLL_ATTEMPTS=3), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Settings', scroll=False))
        self.assertFalse(any(c[:3] == ('shell', 'input', 'swipe') for c in calls))
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps, [('shell', 'input', 'tap', 432, 718)])

    def test_connect_exact_does_not_steal_connect_now(self):
        form = dict(text='', desc='Connect', enabled='true',
                    clickable='true', bounds='[16,600][464,650]')
        now = dict(text='', desc='Connect now', enabled='true',
                   clickable='true', bounds='[33,302][369,350]')
        self.assertTrue(CTRL.node_matches(form, 'Connect', exact=True))
        self.assertFalse(CTRL.node_matches(now, 'Connect', exact=True))
        self.assertTrue(CTRL.node_matches(now, 'Connect now'))
        found = CTRL.locate_text([now, form], 'Connect', exact=True)
        self.assertEqual(found[0]['desc'], 'Connect')

    def test_enter_dashboard_taps_connect_now_then_waits_for_tabs(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        home = [
            dict(text='', desc='Choose a connection', enabled='true',
                 clickable='false', bounds='[16,128][190,151]'),
            dict(text='', desc='Connect now', enabled='true',
                 clickable='true', bounds='[33,302][369,350]'),
        ]
        dashboard = [
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        dumps = [home, dashboard]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl', TAP_SCROLL_ATTEMPTS=3), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.enter_dashboard())
        self.assertFalse(any(c[:3] == ('shell', 'input', 'swipe') for c in calls))
        self.assertEqual([c for c in calls if c[:3] == ('shell', 'input', 'tap')],
                         [('shell', 'input', 'tap', 201, 326)])

    def test_connect_now_is_noop_when_dashboard_tabs_are_already_up(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dashboard = [
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dashboard

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl'), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb):
            asyncio.run(CTRL.tap_text('Connect now'))
        self.assertFalse(calls)


if __name__ == '__main__':
    unittest.main()

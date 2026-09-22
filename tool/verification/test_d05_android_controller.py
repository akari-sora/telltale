#!/usr/bin/env python3
"""Host tests for D05 UI-dump readiness. No emulator and no APK launch."""
from __future__ import annotations

import asyncio
import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
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

    def test_find_system_dialog_detects_anr_and_ignores_valid_ui(self):
        anr_xml = (
            b"<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>"
            b"<hierarchy rotation='0'>"
            b"<node index='0' text='' resource-id='' class='android.widget.FrameLayout' package='android' "
            b"bounds='[64,305][415,470]' enabled='true' clickable='false'>"
            b"<node index='0' text=\"System UI isn't responding\" resource-id='android:id/alertTitle' "
            b"class='android.widget.TextView' package='android' bounds='[88,323][391,351]' enabled='true' clickable='false' />"
            b"<node index='0' text='Close app' resource-id='android:id/aerr_close' class='android.widget.Button' "
            b"package='android' bounds='[64,366][415,414]' enabled='true' clickable='true' />"
            b"<node index='1' text='Wait' resource-id='android:id/aerr_wait' class='android.widget.Button' "
            b"package='android' bounds='[64,414][415,462]' enabled='true' clickable='true' />"
            b"</node></hierarchy>"
        )
        anr_rows = CTRL.parse_ui_rows(anr_xml)
        diag = CTRL.find_system_dialog(anr_rows)
        self.assertIsNotNone(diag)
        self.assertEqual(diag['resource_id'], 'android:id/alertTitle')

        valid_rows = CTRL.parse_ui_rows(VALID_HIERARCHY)
        self.assertIsNone(CTRL.find_system_dialog(valid_rows))


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
            if args[:2] in (('shell', 'input'), ('shell', 'wm'), ('shell', 'svc'), ('shell', 'settings'), ('shell', 'rm'), ('shell', 'uiautomator'), ('exec-out', 'cat')):
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

    def test_dump_dismisses_system_anr_dialog_and_retries(self):
        anr_xml = (
            b"<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>"
            b"<hierarchy rotation='0'>"
            b"<node index='0' text='' resource-id='' class='android.widget.FrameLayout' package='android' "
            b"bounds='[64,305][415,470]' enabled='true' clickable='false'>"
            b"<node index='0' text=\"System UI isn't responding\" resource-id='android:id/alertTitle' "
            b"class='android.widget.TextView' package='android' bounds='[88,323][391,351]' enabled='true' clickable='false' />"
            b"<node index='0' text='Close app' resource-id='android:id/aerr_close' class='android.widget.Button' "
            b"package='android' bounds='[64,366][415,414]' enabled='true' clickable='true' />"
            b"<node index='1' text='Wait' resource-id='android:id/aerr_wait' class='android.widget.Button' "
            b"package='android' bounds='[64,414][415,462]' enabled='true' clickable='true' />"
            b"</node></hierarchy>"
        )
        responses = [anr_xml, VALID_HIERARCHY]
        tap_calls = []

        async def fake_adb(*args, timeout=40, check=True, full=False):
            self.calls.append(args)
            if args[:3] == ('exec-out', 'uiautomator', 'dump'):
                count = len([c for c in self.calls if c[:3] == ('exec-out', 'uiautomator', 'dump')])
                stdout = responses[0] if count == 1 else responses[1]
                result = SimpleNamespace(returncode=0, stdout=stdout, stderr=b'')
                return result if full else stdout
            if args[:3] == ('shell', 'input', 'tap'):
                tap_calls.append(args)
                return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''
            if args[:2] in (('shell', 'input'), ('shell', 'wm'), ('shell', 'svc'), ('shell', 'settings')):
                return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''
            raise AssertionError('unexpected adb args: ' + repr(args))

        async def instant_sleep(_delay):
            return None

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            rows = self._run(CTRL.dump('initial', screenshot=False))
        self.assertEqual(rows[0]['text'], 'Discover Mode 08')
        # Tapped the Wait button at x=(64+415)//2=239, y=(414+462)//2=438
        self.assertEqual(tap_calls, [('shell', 'input', 'tap', '239', '438')])
        # controller.jsonl recorded the detection and dismissal
        events = [json.loads(line) for line in (self.out / 'controller.jsonl').read_text().splitlines()]
        self.assertTrue(any(e.get('event') == 'system_dialog_detected' for e in events))
        self.assertTrue(any(e.get('event') == 'dismiss_system_dialog_action' and e.get('action') == 'tap_wait' for e in events))

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
        self.assertTrue(CTRL.is_recipes_query('Service Recipes'))
        self.assertEqual(
            CTRL.locate_recipes([recipes])[0]['desc'],
            'Service Recipes & Active Tests',
        )

    def test_locate_recipes_accepts_active_tests_first_line(self):
        tile = dict(text='', desc='Active Tests\nWorkshop Mode 08', enabled='true',
                    clickable='true', bounds='[16,400][464,470]')
        found = CTRL.locate_recipes([tile])
        self.assertEqual(found[0]['desc'], tile['desc'])

    def test_recipe_test_labels_keeps_raw_recipe_and_test_descs(self):
        rows = [
            dict(text='', desc='DIAGNOSTIC TRANSCRIPT', enabled='true',
                 clickable='false', bounds='[16,569][464,598]'),
            dict(text='', desc='Telltale Mode 08 Replay Reference', enabled='true',
                 clickable='false', bounds='[33,658][258,676]'),
            dict(text='', desc='Inspect workshop service recipes and discover supported Mode 08 tests',
                 enabled='true', clickable='false', bounds='[16,430][464,470]'),
            dict(text='', desc='Open Service Recipes tile', enabled='true',
                 clickable='true', bounds='[16,400][464,470]'),
        ]
        labels = CTRL.recipe_test_labels(rows)
        self.assertIn(
            'Inspect workshop service recipes and discover supported Mode 08 tests',
            labels,
        )
        self.assertIn('Open Service Recipes tile', labels)
        self.assertNotIn('DIAGNOSTIC TRANSCRIPT', labels)
        self.assertEqual(
            CTRL.locate_recipes(rows)[0]['desc'],
            'Open Service Recipes tile',
        )

    def test_locate_recipes_prefers_titled_tile_over_empty_parent(self):
        empty = dict(text='', desc='', enabled='true', clickable='true',
                     bounds='[0,24][480,752]')
        subtitle = dict(
            text='',
            desc='Inspect workshop service recipes and discover supported Mode 08 tests',
            enabled='true', clickable='false', bounds='[16,430][464,470]',
        )
        tile = dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                    clickable='true', bounds='[16,400][464,470]')
        found = CTRL.locate_recipes([empty, subtitle, tile])
        self.assertEqual(found[0]['desc'], 'Service Recipes & Active Tests')
        self.assertEqual(found[1:], (240, 435))
        self.assertIsNone(CTRL.locate_recipes([empty]))
        self.assertEqual(CTRL.node_primary_label(tile), 'Service Recipes & Active Tests')
        self.assertEqual(CTRL.node_primary_label(empty), '')

    def _swipe_calls(self, calls):
        return [c for c in calls if c[:1] == ('shell',) and any(
            isinstance(part, str) and 'swipe' in part for part in c)]

    def _page_calls(self, calls):
        return [c for c in calls if len(c) >= 4 and c[:3] == ('shell', 'input', 'keyevent')]

    def _runtest_calls(self, calls):
        return [c for c in calls if len(c) >= 3 and c[1] == 'uiautomator' and 'runtest' in c]

    def _settings_bottom_rows(self):
        """Job 16610280973 ui_op8_fail — Settings bottom, not Dashboard."""
        return [
            dict(text='', desc='Gauge style\nNot just a colour change — each one has a different degree.',
                 enabled='true', clickable='false', bounds='[16,24][464,163]'),
            dict(text='', desc='Cluster', enabled='true', clickable='true',
                 bounds='[33,24][165,102]'),
            dict(text='', desc='2740 rpm, RPM', enabled='true', clickable='false',
                 bounds='[43,24][155,74]'),
            dict(text='', desc='RECOMMENDED ADAPTER\nCARLZS LAB CL-OBDII-M25B',
                 enabled='true', clickable='false', bounds='[16,187][464,486]'),
            dict(text='', desc='Open source and data licences', enabled='true',
                 clickable='true', bounds='[16,502][464,550]'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]

    def test_settings_list_open_rejects_dashboard_gauges_and_home(self):
        title = dict(text='', desc='Settings', enabled='true',
                     clickable='false', bounds='[16,36][464,63]')
        connection = dict(text='', desc='CONNECTION', enabled='true',
                          clickable='false', bounds='[16,87][464,116]')
        tab = dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                   clickable='true', bounds='[384,684][480,752]')
        gauges = [
            dict(text='', desc='No data — Unverified · Partial · No answer — will retry, RPM',
                 enabled='true', clickable='false', bounds='[25,24][225,109]'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
            tab,
        ]
        home = [
            dict(text='', desc='Choose a connection', enabled='true',
                 clickable='false', bounds='[16,128][190,151]'),
        ]
        self.assertTrue(CTRL.settings_list_open([title, tab]))
        self.assertTrue(CTRL.settings_list_open([connection, tab]))
        self.assertFalse(CTRL.settings_list_open(gauges))
        self.assertTrue(CTRL.dashboard_surface(gauges))
        self.assertFalse(CTRL.settings_list_open(home))
        self.assertFalse(CTRL.dashboard_surface(home))
        self.assertTrue(CTRL.session_dropped(home))
        dropped_sheet = [
            dict(text='', desc='The adapter stopped responding and the connection has been dropped.',
                 enabled='true', clickable='false', bounds='[65,45][447,87]'),
            dict(text='', desc='Full disclosure in Settings', enabled='true',
                 clickable='true', bounds='[16,672][217,720]'),
        ]
        self.assertTrue(CTRL.session_dropped(dropped_sheet))
        self.assertFalse(CTRL.session_dropped(gauges))

    def test_settings_bottom_is_list_not_dashboard(self):
        bottom = self._settings_bottom_rows()
        self.assertTrue(CTRL.settings_list_open(bottom))
        self.assertFalse(CTRL.dashboard_surface(bottom))
        self.assertTrue(CTRL.past_recipes(bottom))
        self.assertFalse(CTRL.session_dropped(bottom))
        self.assertFalse(CTRL.still_above_recipes(bottom))

    def _vehicle_profile_mid_rows(self):
        """Job 16610428447 ui_1843 — headers scrolled off, still Settings."""
        return [
            dict(text='', desc='Horsepower, torque and fuel use are estimated from these parameters; the closer they are to the actual vehicle, the more the estimates mean.\nA brand name or a VIN alone does not establish mass.',
                 enabled='true', clickable='false', bounds='[16,24][464,684]',
                 clazz='android.view.View'),
            dict(text='', desc='Choose from the official catalog', enabled='true',
                 clickable='true', bounds='[33,180][447,228]',
                 clazz='android.widget.Button'),
            dict(text='', desc='18%', enabled='true', clickable='true',
                 bounds='[99,415][147,463]', clazz='android.widget.SeekBar'),
            dict(text='', desc='31%', enabled='true', clickable='true',
                 bounds='[147,492][195,540]', clazz='android.widget.SeekBar'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]',
                 clazz='android.widget.Button'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]',
                 clazz='android.widget.Button'),
        ]

    def test_vehicle_profile_mid_scroll_is_list_not_dashboard(self):
        mid = self._vehicle_profile_mid_rows()
        self.assertTrue(CTRL.settings_list_open(mid))
        self.assertFalse(CTRL.dashboard_surface(mid))
        self.assertTrue(CTRL.still_above_recipes(mid))
        self.assertFalse(CTRL.past_recipes(mid))
        self.assertFalse(CTRL.session_dropped(mid))
        self.assertTrue(CTRL.visible_seekbars(mid))
        self.assertFalse(CTRL.point_hits_seekbar(CTRL.LIST_FOCUS_X, CTRL.LIST_FOCUS_Y, mid))
        self.assertTrue(CTRL.point_hits_seekbar(120, 430, mid))

    def test_reconnect_dashboard_gauges_are_not_settings_list(self):
        gauges = [
            dict(text='', desc='Start recording', enabled='true',
                 clickable='true', bounds='[33,397][447,445]'),
            dict(text='', desc=('Records only the OBD signals you have enabled — no location, '
                               'VIN, or account data. Trends show at most 4 signals; a recording '
                               'keeps all 6 enabled signals and adds estimated horsepower and '
                               'estimated fuel rate, which rest on the vehicle assumptions.'),
                 enabled='true', clickable='false', bounds='[59,295][447,385]'),
            dict(text='', desc='800 rpm (data is stale) — Unverified · Stale, RPM',
                 enabled='true', clickable='false', bounds='[25,487][225,684]'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        self.assertFalse(CTRL.settings_list_open(gauges))
        self.assertTrue(CTRL.dashboard_surface(gauges))

    def test_seekbars_with_settings_tab_count_as_list(self):
        rows = [
            dict(text='', desc='18%', enabled='true', clickable='true',
                 bounds='[99,415][147,463]', clazz='android.widget.SeekBar'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        self.assertTrue(CTRL.settings_list_open(rows))
        self.assertFalse(CTRL.dashboard_surface(rows))

    def test_recipes_scrolls_into_view_from_vehicle_profile_body(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        connection = [
            dict(text='', desc='CONNECTION', enabled='true',
                 clickable='false', bounds='[16,87][464,116]'),
            dict(text='', desc='VEHICLE PROFILE', enabled='true',
                 clickable='false', bounds='[16,418][464,447]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        recipes = [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                        clickable='true', bounds='[16,400][464,470]')]
        dumps = [connection, recipes]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=4, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        events = (out / 'controller.jsonl').read_text()
        self.assertNotIn('settings_residency_lost', events)
        self.assertNotIn('settings_tab_retap', events)
        self.assertTrue(self._page_calls(calls))
        self.assertTrue(self._swipe_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))

    def _fuel_and_drivetrain_rows(self):
        """Job 16610532958 ui_1785 / ui_fail — PAGE_DOWN no-op surface."""
        return [
            dict(text='', desc='Horsepower, torque and fuel use are estimated from these parameters; the closer they are to the actual vehicle, the more the estimates mean.\nDisplacement\n2.0 L',
                 enabled='true', clickable='false', bounds='[16,24][464,345]',
                 clazz='android.view.View'),
            dict(text='', desc='44%', enabled='true', clickable='true',
                 bounds='[193,41][241,89]', clazz='android.widget.SeekBar'),
            dict(text='', desc='FUEL AND DRIVETRAIN', enabled='true',
                 clickable='false', bounds='[16,361][464,390]',
                 clazz='android.view.View'),
            dict(text='', desc='Fuel type\nAir-fuel ratio 14.7 · density 740 g/L\nDrivetrain',
                 enabled='true', clickable='false', bounds='[16,390][464,684]',
                 clazz='android.view.View'),
            dict(text='', desc='Petrol', enabled='true', clickable='true',
                 bounds='[33,428][104,476]', clazz='android.widget.Button'),
            dict(text='', desc='Diesel', enabled='true', clickable='true',
                 bounds='[112,428][183,476]', clazz='android.widget.Button'),
            dict(text='', desc='Front-wheel drive', enabled='true', clickable='true',
                 bounds='[33,535][175,583]', clazz='android.widget.Button'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]',
                 clazz='android.widget.Button'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]',
                 clazz='android.widget.Button'),
        ]

    def test_fuel_chips_do_not_steal_gutter_focus(self):
        fuel = self._fuel_and_drivetrain_rows()
        self.assertTrue(CTRL.settings_list_open(fuel))
        self.assertFalse(CTRL.dashboard_surface(fuel))
        self.assertTrue(CTRL.still_above_recipes(fuel))
        self.assertEqual(CTRL.dump_fingerprint(fuel), CTRL.dump_fingerprint(fuel))
        self.assertTrue(CTRL.point_hits_interactive(48, 450, fuel))
        self.assertTrue(CTRL.point_hits_interactive(80, 450, fuel))
        self.assertFalse(CTRL.point_hits_interactive(CTRL.LIST_FOCUS_X, 450, fuel))
        self.assertFalse(CTRL.point_hits_interactive(CTRL.LIST_FOCUS_X, CTRL.LIST_FOCUS_Y, fuel))

    def test_fuel_viewport_scrolls_recipes_into_view_without_page_down(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        fuel = self._fuel_and_drivetrain_rows()
        recipes = [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                        clickable='true', bounds='[16,400][464,470]')]
        dumps = [fuel, recipes]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=4, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        events = (out / 'controller.jsonl').read_text()
        self.assertNotIn('recipes_page_stuck', events)
        self.assertNotIn('recipes_gutter_nudge', events)
        self.assertNotIn('settings_residency_lost', events)
        self.assertNotIn('recipes_burst_fling', events)
        self.assertTrue(self._page_calls(calls))
        self.assertTrue(self._swipe_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))

    def test_tap_text_scrolls_recipes_into_view_without_page_down(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dumps = [
            [
                dict(text='', desc='CONNECTION', enabled='true',
                     clickable='false', bounds='[16,87][464,116]'),
                dict(text='', desc='DIAGNOSTIC TRANSCRIPT', enabled='true',
                     clickable='false', bounds='[16,569][464,598]'),
                dict(text='', desc='Telltale Mode 08 test replay', enabled='true',
                     clickable='false', bounds='[33,658][258,676]'),
            ],
            [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                  clickable='true', bounds='[16,400][464,470]')],
        ]
        calls = []
        order = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            order.append('dump')
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            if args[:3] == ('shell', 'input', 'tap'):
                order.append('tap')
            elif args[:3] == ('shell', 'input', 'keyevent'):
                order.append('page')
            elif len(args) >= 2 and args[1] == 'uiautomator':
                order.append('scroll')
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        self.assertEqual(order, ['dump', 'page', 'dump', 'tap'])
        self.assertTrue(self._swipe_calls(calls))
        self.assertTrue(self._page_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('recipes_direct_nav', events)
        self.assertIn('page_down', events)
        self.assertIn('"method": "page_down"', events)
        self.assertIn('"settings_list": true', events)
        self.assertIn('"node_label": "Service Recipes & Active Tests"', events)
        self.assertNotIn('recipes_burst_fling', events)
        self.assertNotIn('recipes_page_scroll', events)

    def test_recipes_retaps_settings_when_dashboard_is_showing(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        gauges = [
            dict(text='', desc='No data — Unverified · Partial · No answer — will retry, RPM',
                 enabled='true', clickable='false', bounds='[25,24][225,109]'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        settings_top = [
            dict(text='', desc='Settings', enabled='true',
                 clickable='false', bounds='[16,36][464,63]'),
            dict(text='', desc='CONNECTION', enabled='true',
                 clickable='false', bounds='[16,87][464,116]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        recipes = [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                        clickable='true', bounds='[16,400][464,470]')]
        dumps = [gauges, settings_top, recipes]
        calls = []
        order = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            order.append('dump')
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            if args[:3] == ('shell', 'input', 'tap'):
                order.append('tap')
            elif args[:3] == ('shell', 'input', 'keyevent'):
                order.append('page')
            elif len(args) >= 2 and args[1] == 'uiautomator':
                order.append('scroll')
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        self.assertEqual(order, ['dump', 'tap', 'dump', 'page', 'dump', 'tap'])
        self.assertTrue(self._swipe_calls(calls))
        self.assertTrue(self._page_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[0], ('shell', 'input', 'tap', 432, 718))
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('settings_residency_lost', events)
        self.assertIn('recipes_direct_nav', events)
        self.assertIn('page_down', events)

    def test_recipes_scrolls_into_view_from_settings_bottom_without_retap(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dumps = [
            self._settings_bottom_rows(),
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

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        self.assertTrue(self._swipe_calls(calls))
        self.assertTrue(self._page_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('"method": "page_down"', events)
        self.assertNotIn('settings_residency_lost', events)
        self.assertNotIn('recipes_burst_fling', events)

    def test_recipes_scrolls_into_view_from_language_overshoot(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dumps = [
            [
                dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                     clickable='true', bounds='[384,684][480,752]'),
                dict(text='', desc='Language / 語言', enabled='true',
                     clickable='false', bounds='[16,200][464,230]'),
                dict(text='', desc='Appearance', enabled='true',
                     clickable='false', bounds='[16,300][464,330]'),
            ],
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

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        self.assertTrue(self._swipe_calls(calls))
        self.assertTrue(self._page_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)

    def test_scroll_into_view_fails_closed_when_jar_unusable(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        calls = []

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            SCROLL_JAR_TRIED=True, SCROLL_JAR_USABLE=False), \
                patch.object(CTRL, 'adb', fake_adb):
            with self.assertRaises(CTRL.ScrollJarUnusable):
                asyncio.run(CTRL.scroll_into_view('Service Recipes'))
        self.assertFalse(self._runtest_calls(calls))
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('scroll_jar_unusable', events)
        self.assertNotIn('scroll_jar_skipped', events)

    def test_recipes_reconnects_once_after_session_drop(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dropped = [
            dict(text='', desc='Choose a connection', enabled='true',
                 clickable='false', bounds='[16,128][190,151]'),
            dict(text='', desc='Connect now', enabled='true',
                 clickable='true', bounds='[33,302][369,350]'),
        ]
        tabs = [
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
        ]
        recipes = [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                        clickable='true', bounds='[16,400][464,470]')]
        # dump dropped → enter_dashboard (dump tabs) → Settings find (dump
        # tabs) → tap Settings → dump recipes
        dumps = [dropped, tabs, tabs, recipes]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('recipes_session_dropped', events)
        self.assertNotIn('recipes_burst_fling', events)
        self.assertFalse(self._runtest_calls(calls))
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[0], ('shell', 'input', 'tap', 432, 718))
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))

    def test_recipes_pages_after_reconnect_from_connection(self):
        """Formal op8 path: reconnect + Settings lands on CONNECTION."""
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dropped = [
            dict(text='', desc='Choose a connection', enabled='true',
                 clickable='false', bounds='[16,128][190,151]'),
            dict(text='', desc='Connect now', enabled='true',
                 clickable='true', bounds='[33,302][369,350]'),
        ]
        tabs = [
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
        ]
        connection = [
            dict(text='', desc='CONNECTION', enabled='true',
                 clickable='false', bounds='[16,87][464,116]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        recipes = [dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                        clickable='true', bounds='[16,400][464,470]')]
        # dump dropped → enter_dashboard (dump tabs) → Settings find (dump
        # tabs) → tap Settings → dump CONNECTION → scrollIntoView → dump recipes
        dumps = [dropped, tabs, tabs, connection, recipes]
        calls = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('recipes_session_dropped', events)
        self.assertIn('"method": "page_down"', events)
        self.assertNotIn('recipes_burst_fling', events)
        self.assertNotIn('settings_residency_lost', events)
        self.assertTrue(self._swipe_calls(calls))
        self.assertTrue(self._page_calls(calls))
        self.assertEqual(len(self._runtest_calls(calls)), 0)
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(taps[0], ('shell', 'input', 'tap', 432, 718))
        self.assertEqual(taps[-1], ('shell', 'input', 'tap', 240, 435))

    def test_non_recipe_text_still_dumps_before_flinging(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dumps = [
            [dict(text='', desc='Bluetooth LE', enabled='true', clickable='true',
                  bounds='[16,24][464,96]')],
            [dict(text='', desc='Wi-Fi\nA TCP port', enabled='true', clickable='true',
                  bounds='[16,398][464,473]')],
        ]
        calls = []
        order = []

        async def fake_dump(label='view', screenshot=True, prepare=True):
            order.append('dump')
            return dumps.pop(0)

        async def fake_adb(*args, timeout=40, check=True, full=False):
            calls.append(args)
            if args[:1] == ('shell',) and any(
                    isinstance(part, str) and 'swipe' in part for part in args):
                order.append('swipe')
            result = SimpleNamespace(returncode=0, stdout=b'', stderr=b'')
            return result if full else b''

        async def instant_sleep(_delay):
            return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl', TAP_SCROLL_ATTEMPTS=3), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Wi-Fi'))
        self.assertEqual(order[:3], ['dump', 'swipe', 'dump'])
        swipes = self._swipe_calls(calls)
        self.assertEqual(len(swipes), 1)
        self.assertEqual(swipes[0][1].count('input swipe'), CTRL.FLINGS_PER_LOOK)

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

    def test_enter_dashboard_taps_connect_when_connect_now_absent(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        wifi_form = [
            dict(text='', desc='Choose a connection', enabled='true',
                 clickable='false', bounds='[16,128][190,151]'),
            dict(text='', desc='Connect', enabled='true',
                 clickable='true', bounds='[33,405][168,415]'),
        ]
        dashboard = [
            dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                 clickable='true', bounds='[0,684][96,752]'),
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        dumps = [wifi_form, dashboard]
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
        self.assertEqual([c for c in calls if c[:3] == ('shell', 'input', 'tap')],
                         [('shell', 'input', 'tap', 100, 410)])

    def test_enter_dashboard_taps_wifi_then_connect_on_dropped_session(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dropped = [
            dict(text='', desc='The adapter stopped responding and the connection has been dropped.',
                 enabled='true', clickable='false', bounds='[65,46][447,88]'),
            dict(text='', desc='Wi-Fi\nA TCP port, usually 192.168.0.10:35000',
                 enabled='true', clickable='true', bounds='[16,399][464,474]'),
        ]
        wifi_form = [
            dict(text='', desc='The adapter stopped responding and the connection has been dropped.',
                 enabled='true', clickable='false', bounds='[65,46][447,88]'),
            dict(text='', desc='Connect', enabled='true',
                 clickable='true', bounds='[33,405][168,415]'),
        ]
        dashboard = [
            dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                 clickable='true', bounds='[384,684][480,752]'),
        ]
        dumps = [dropped, wifi_form, dashboard]
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
        taps = [c for c in calls if c[:3] == ('shell', 'input', 'tap')]
        self.assertEqual(len(taps), 2)
        self.assertEqual(taps[0], ('shell', 'input', 'tap', 240, 436))
        self.assertEqual(taps[1], ('shell', 'input', 'tap', 100, 410))

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


class ScrollJarCompileTests(unittest.TestCase):
    def test_device_dex_jar_is_not_java_stubs(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        dex = Path(tmp.name) / 'uiautomator.jar'
        with zipfile.ZipFile(dex, 'w') as archive:
            archive.writestr('META-INF/MANIFEST.MF', 'Manifest-Version: 1.0\n')
            archive.writestr('classes.dex', b'dex\n035\x00')
        self.assertFalse(CTRL._jar_has_class_files(dex))
        classes = Path(tmp.name) / 'stubs.jar'
        with zipfile.ZipFile(classes, 'w') as archive:
            archive.writestr(
                'com/android/uiautomator/core/UiSelector.class',
                b'\xca\xfe\xba\xbe',
            )
        self.assertTrue(CTRL._jar_has_class_files(classes))

    def test_android_jar_uses_opt_sdk_without_env(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name) / 'android-sdk-linux'
        jar = root / 'platforms' / 'android-29' / 'android.jar'
        jar.parent.mkdir(parents=True)
        jar.write_bytes(b'pk')
        with patch.object(CTRL, '_sdk_roots', return_value=[root]):
            self.assertEqual(CTRL._android_jar(), jar)
            self.assertIsNone(CTRL._host_uiautomator_jar())

    def test_host_uiautomator_ignores_dex_and_accepts_class_jar(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name) / 'sdk'
        dex = root / 'platforms' / 'android-29' / 'uiautomator.jar'
        dex.parent.mkdir(parents=True)
        with zipfile.ZipFile(dex, 'w') as archive:
            archive.writestr('classes.dex', b'dex\n035\x00')
        stubs = root / 'platforms' / 'android-23' / 'uiautomator.jar'
        stubs.parent.mkdir(parents=True)
        with zipfile.ZipFile(stubs, 'w') as archive:
            archive.writestr('com/android/uiautomator/core/UiScrollable.class',
                             b'\xca\xfe\xba\xbe')
        with patch.object(CTRL, '_sdk_roots', return_value=[root]):
            self.assertEqual(CTRL._host_uiautomator_jar(), stubs)

    def test_compile_stubs_are_present(self):
        sources = sorted(CTRL.SCROLL_STUBS_DIR.rglob('*.java'))
        names = [str(path.relative_to(CTRL.SCROLL_STUBS_DIR)) for path in sources]
        self.assertIn('com/android/uiautomator/core/UiScrollable.java', names)
        self.assertIn('com/android/uiautomator/testrunner/UiAutomatorTestCase.java', names)

    def test_ensure_scroll_jar_fails_closed_when_tools_missing(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            SCROLL_JAR_TRIED=False, SCROLL_JAR_USABLE=False), \
                patch.object(CTRL, '_javac', return_value=None), \
                patch.object(CTRL, '_android_jar', return_value=None), \
                patch.object(CTRL, '_dexer', return_value=None):
            with self.assertRaises(CTRL.ScrollJarUnusable):
                asyncio.run(CTRL.ensure_scroll_jar())
        events = (out / 'controller.jsonl').read_text()
        self.assertIn('scroll_jar_unusable', events)
        self.assertIn('missing_javac', events)
        self.assertNotIn('scroll_jar_skipped', events)
        self.assertNotIn('scroll_jar_compile_skipped', events)


class Mode01KeepaliveTests(unittest.TestCase):
    def test_dashboard_pids_are_keepalive_and_mode08_is_not(self):
        self.assertIn('41 5E 00 00', CTRL.mode01_keepalive_line('015E'))
        self.assertIn('41 0C 0C 80', CTRL.mode01_keepalive_line('010C'))
        self.assertIn('7E8 04 41 5E 00 00',
                      CTRL.mode01_keepalive_line('015E', headers=True))
        self.assertEqual(CTRL.mode01_keepalive_line('015E', spaces=False), '415E0000')
        self.assertIn('41 0C', CTRL.mode01_keepalive_line('010C0D04110B10'))
        self.assertIn('41 2F 00', CTRL.mode01_keepalive_line('012F'))
        self.assertIsNone(CTRL.mode01_keepalive_line('0800'))
        self.assertIsNone(CTRL.mode01_keepalive_line('0820'))
        self.assertIsNone(CTRL.mode01_keepalive_line('0100'))
        self.assertIsNone(CTRL.mode01_keepalive_line('ATRV'))
        self.assertIsNone(CTRL.mode01_keepalive_line('0902'))

    def test_device_rig_answers_015e_without_consuming_mode08_step(self):
        from mode08_replay_reference import AdapterState

        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)

        class DummyWriter:
            def __init__(self):
                self.connection = 1
                self.output = []
                self.closed = False

            def write(self, data):
                self.output.append(data)

            async def drain(self):
                return None

            def close(self):
                self.closed = True

            async def wait_closed(self):
                return None

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl'):
            rig = CTRL.DeviceRig()
            state = AdapterState()
            state.headers = True
            state.active_scenario_id = 'normal_headered_multi_block'
            writer = DummyWriter()
            asyncio.run(rig.process_command('015E', state, writer))
            self.assertEqual(state.step_index, 0)
            self.assertTrue(any(b'41 5E' in chunk for chunk in writer.output))
            self.assertFalse(any(b'48 00' in chunk for chunk in writer.output))
            writer.output.clear()
            asyncio.run(rig.process_command('ATRV', state, writer))
            self.assertEqual(state.step_index, 0)
            self.assertTrue(any(b'12.6V' in chunk for chunk in writer.output))
            writer.output.clear()
            asyncio.run(rig.process_command('0800', state, writer))
            self.assertEqual(state.step_index, 1)
            self.assertTrue(any(b'48 00 80 00 00 01' in chunk for chunk in writer.output))
        events = (out / 'controller.jsonl').read_text()
        self.assertNotIn('tcp_keepalive_reply', events)
        self.assertNotIn('"command": "015E"', events)



class DashboardSurfaceRoadTest(unittest.TestCase):
    def test_road_test_started_is_dashboard_not_settings(self):
        rows = [
            {'text': '', 'desc': 'Road test started', 'bounds': '[16,200][464,260]',
             'enabled': 'true', 'clickable': 'false', 'clazz': 'android.widget.TextView'},
            {'text': '', 'desc': 'Dashboard\nTab 1 of 5', 'bounds': '[0,684][96,752]',
             'enabled': 'true', 'clickable': 'true', 'clazz': 'android.widget.Button'},
            {'text': '', 'desc': 'Settings\nTab 5 of 5', 'bounds': '[384,684][480,752]',
             'enabled': 'true', 'clickable': 'true', 'clazz': 'android.widget.Button'},
        ]
        self.assertTrue(CTRL.dashboard_surface(rows))
        self.assertFalse(CTRL.settings_list_open(rows))

    def test_recipes_tile_clickable_false_still_locates(self):
        rows = [
            {'text': '',
             'desc': 'Service Recipes & Active Tests\nInspect workshop service recipes and discover supported Mode 08 tests',
             'bounds': '[16,295][464,399]',
             'enabled': 'true', 'clickable': 'false', 'clazz': 'android.widget.Button'},
        ]
        found = CTRL.locate_recipes(rows)
        self.assertIsNotNone(found)
        row, x, y = found
        self.assertEqual(x, (16 + 464) // 2)
        self.assertEqual(y, (295 + 399) // 2)



class LauncherSurfaceTests(unittest.TestCase):
    def test_apps_list_is_launcher_not_connect(self):
        rows = [
            {'text': 'Gallery', 'desc': 'Gallery', 'bounds': '[16,200][120,300]',
             'enabled': 'true', 'clickable': 'true', 'clazz': 'android.widget.TextView'},
            {'text': '', 'desc': 'Apps list', 'bounds': '[16,40][200,80]',
             'enabled': 'true', 'clickable': 'true', 'clazz': 'android.widget.TextView'},
        ]
        self.assertTrue(CTRL.launcher_surface(rows))
        self.assertFalse(CTRL.launcher_surface([
            {'text': '', 'desc': 'Wi-Fi\nA TCP port', 'bounds': '[16,465][464,540]',
             'enabled': 'true', 'clickable': 'true', 'clazz': 'android.widget.Button'},
        ]))


class OvershootRecoveryTests(unittest.TestCase):
    def test_past_recipes_causes_upward_scroll_and_page_up(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        out = Path(tmp.name)
        dumps = [
            [
                dict(text='', desc='Gauge style\nNot just a colour change.', enabled='true',
                     clickable='false', bounds='[16,24][464,163]'),
                dict(text='', desc='RECOMMENDED ADAPTER', enabled='true',
                     clickable='false', bounds='[16,187][464,486]'),
                dict(text='', desc='Dashboard\nTab 1 of 5', enabled='true',
                     clickable='true', bounds='[0,684][96,752]'),
                dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                     clickable='true', bounds='[384,684][480,752]'),
            ],
            [
                dict(text='', desc='Service Recipes & Active Tests', enabled='true',
                     clickable='true', bounds='[16,400][464,470]'),
                dict(text='', desc='Settings\nTab 5 of 5', enabled='true',
                     clickable='true', bounds='[384,684][480,752]'),
            ],
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

        with patch.multiple(CTRL, OUT=out, EVENT_FILE=out / 'controller.jsonl',
                            TAP_SCROLL_ATTEMPTS=3, SCROLL_JAR_TRIED=True,
                            SCROLL_JAR_USABLE=True), \
                patch.object(CTRL, 'dump', fake_dump), \
                patch.object(CTRL, 'adb', fake_adb), \
                patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.tap_text('Service Recipes'))

        events = (out / 'controller.jsonl').read_text()
        self.assertIn('"overshoot_recovery": true', events)
        page_up_calls = [c for c in calls if len(c) >= 4 and c[3] == 'KEYCODE_PAGE_UP']
        self.assertTrue(len(page_up_calls) > 0)
        swipes = [c for c in calls if c[:1] == ('shell',) and any(isinstance(part, str) and 'swipe' in part for part in c)]
        self.assertTrue(len(swipes) > 0)


class Mode08TerminalAssertionTests(unittest.TestCase):
    def test_rejects_empty_rows(self):
        with self.assertRaisesRegex(RuntimeError, 'empty'):
            CTRL.assert_genuine_mode08_terminal([])

    def test_rejects_connect_now(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='Connect now'),
        ]
        with self.assertRaisesRegex(RuntimeError, 'dropped back to Connect screen'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_rejects_choose_a_connection(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='Choose a connection'),
        ]
        with self.assertRaisesRegex(RuntimeError, 'dropped back to Connect screen'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_rejects_last_adapter_used(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='Last adapter used'),
        ]
        with self.assertRaisesRegex(RuntimeError, 'dropped back to Connect screen'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_rejects_connection_layer_resource_id(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='Wi-Fi', resource_id='connection-layer-transport-wifi'),
        ]
        with self.assertRaisesRegex(RuntimeError, 'dropped back to Connect screen'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_rejects_session_dropped(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='The adapter stopped responding', desc=''),
        ]
        with self.assertRaisesRegex(RuntimeError, 'dropped back to Connect screen'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_rejects_when_not_on_service_recipes_surface(self):
        rows = [
            dict(text='', desc='Dashboard\nTab 1 of 5'),
            dict(text='Mode 08 is supported by ECU. Supported TIDs: $01, $20', desc=''),
        ]
        with self.assertRaisesRegex(RuntimeError, 'not on Service Recipes screen'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_rejects_when_outcome_is_missing(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='MODE 08 NON-ACTUATING DISCOVERY'),
            dict(text='', desc='Discover Mode 08 Supported TIDs'),
        ]
        with self.assertRaisesRegex(RuntimeError, 'does not contain genuine Mode 08 outcome'):
            CTRL.assert_genuine_mode08_terminal(rows)

    def test_accepts_supported_tids_outcome(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='MODE 08 NON-ACTUATING DISCOVERY'),
            dict(text='Mode 08 is supported by ECU. Supported TIDs: $01, $20', desc=''),
            dict(text='', desc='TID $01'),
            dict(text='', desc='TID $20'),
        ]
        self.assertTrue(CTRL.assert_genuine_mode08_terminal(rows))

    def test_accepts_unsupported_outcome(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='MODE 08 NON-ACTUATING DISCOVERY'),
            dict(text='Mode 08 is not supported by this ECU', desc=''),
        ]
        self.assertTrue(CTRL.assert_genuine_mode08_terminal(rows))

    def test_accepts_unknown_or_timeout_outcome(self):
        rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics'),
            dict(text='', desc='MODE 08 NON-ACTUATING DISCOVERY'),
            dict(text='Mode 08 support is unknown: Mode 08 query timed out', desc=''),
        ]
        self.assertTrue(CTRL.assert_genuine_mode08_terminal(rows))


class LaunchAppResumeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.calls = []

    def _run(self, coro):
        return asyncio.run(coro)

    def _patch_out(self):
        return patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.out / 'controller.jsonl')

    def test_launch_app_resume_skips_focus_wait_and_completes_promptly(self):
        dumpsys = [
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
            self._run(CTRL.launch_app(is_resume=True))

        self.assertTrue(any(c[:3] == ('shell', 'am', 'start') for c in self.calls))
        self.assertEqual(len([c for c in self.calls if c[:3] == ('shell', 'dumpsys', 'activity')]), 1)
        self.assertFalse(any(c[:3] == ('shell', 'dumpsys', 'window') for c in self.calls))
        events = (self.out / 'controller.jsonl').read_text()
        self.assertIn('"event": "app_resumed_ready"', events)


class CaseHoldAndReleaseOrderTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.event_file = self.out / 'controller.jsonl'

    def _patch_out(self):
        return patch.multiple(CTRL, OUT=self.out, EVENT_FILE=self.event_file)

    def test_case_releases_hold_timely_and_asserts_terminal(self):
        events_recorded = []

        class MockRig:
            def __init__(self):
                self.target = None
                self.held = None
                self.release = None
                self.states = {}

            def arm(self, command):
                self.target = command
                loop = asyncio.get_running_loop()
                self.held = loop.create_future()
                self.release = asyncio.Event()
                self.held.set_result({'connection': 2, 'command': command})

        rig = MockRig()
        genuine_terminal_rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics', enabled='true', bounds='[0,0][480,100]'),
            dict(text='', desc='MODE 08 NON-ACTUATING DISCOVERY', enabled='true', bounds='[0,100][480,200]'),
            dict(text='Mode 08 is not supported by this ECU', desc='', enabled='true', bounds='[0,200][480,300]'),
            dict(text='Discover Mode 08', desc='', enabled='true', clickable='true', bounds='[10,20][100,80]'),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            if 'keyevent' in args:
                await asyncio.sleep(0.01)
            stdout = b''
            if 'dumpsys' in args and 'activity' in args:
                stdout = b'Stack #0: type=home com.android.launcher3/.Launcher'
            elif 'dumpsys' in args and 'power' in args:
                stdout = b'mWakefulness=Asleep mLastSleepReason=sleep_button'
            return SimpleNamespace(returncode=0, stdout=stdout, stderr=b'') if full else stdout

        async def fake_dump(label, screenshot=True, prepare=True):
            return genuine_terminal_rows

        async def fake_find_text(text, exact=False, scroll=True):
            node = dict(text=text, desc='', bounds='[10,20][100,80]')
            return (node, 50, 50), 0

        async def fake_launch_app(is_resume=False):
            pass

        async def fake_actual_os_snapshot(label):
            pass

        async def fake_wait_for_mode08_terminal_ui(timeout=30):
            return genuine_terminal_rows

        async def instant_sleep(_delay):
            pass

        with self._patch_out(), \
             patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'dump', fake_dump), \
             patch.object(CTRL, 'find_text', fake_find_text), \
             patch.object(CTRL, 'launch_app', fake_launch_app), \
             patch.object(CTRL, 'wait_for_mode08_terminal_ui', fake_wait_for_mode08_terminal_ui), \
             patch.object(CTRL, 'actual_os_snapshot', fake_actual_os_snapshot), \
             patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.case(rig, 1, 'Discover Mode 08'))

        lines = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        event_names = [e['event'] for e in lines]

        # Verify hold released strictly AFTER OS command execution and verification during hold
        self.assertIn('held_query_confirmed_before_os_command', event_names)
        self.assertIn('os_command_executed_during_hold', event_names)
        self.assertIn('mode08_hold_released_for_resume', event_names)
        self.assertIn('case_observations_complete', event_names)

        # Confirm order: held query -> OS command executed during hold -> hold released -> complete
        held_idx = event_names.index('held_query_confirmed_before_os_command')
        os_cmd_idx = event_names.index('os_command_executed_during_hold')
        rel_idx = event_names.index('mode08_hold_released_for_resume')
        complete_idx = event_names.index('case_observations_complete')

        self.assertLess(held_idx, os_cmd_idx)
        self.assertLess(os_cmd_idx, rel_idx)
        self.assertLess(rel_idx, complete_idx)

        # Confirm acceptance marker
        comp_event = [e for e in lines if e['event'] == 'case_observations_complete'][0]
        self.assertEqual(comp_event['acceptance'], 'CONFIRMED_TERMINAL_UI')

    def test_setup_fast_lifecycle_helpers_pushes_scripts(self):
        calls = []
        async def fake_adb(*args, **kwargs):
            calls.append(args)
            return b''

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb):
            asyncio.run(CTRL.setup_fast_lifecycle_helpers())

        pushed_files = [c[2] for c in calls if c and c[0] == 'push']
        self.assertIn('/data/local/tmp/d05_power.sh', pushed_files)
        self.assertIn('/data/local/tmp/d05_home.sh', pushed_files)
        chmod_calls = [c for c in calls if c and c[0] == 'shell' and c[1] == 'chmod']
        self.assertTrue(len(chmod_calls) > 0)

    def test_setup_fast_lifecycle_helpers_native_elf_on_linux(self):
        calls = []
        async def fake_adb(*args, **kwargs):
            calls.append(args)
            return b''

        def fake_subprocess_run(cmd, capture_output=True):
            return subprocess.CompletedProcess(cmd, 0, stdout=b'', stderr=b'')

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL.sys, 'platform', 'linux'), \
             patch.object(CTRL.shutil, 'which', lambda x: '/usr/bin/gcc'), \
             patch.object(CTRL.subprocess, 'run', fake_subprocess_run):
            asyncio.run(CTRL.setup_fast_lifecycle_helpers())

        pushed_files = [c[2] for c in calls if c and c[0] == 'push']
        self.assertIn('/data/local/tmp/d05_power.sh', pushed_files)
        self.assertIn('/data/local/tmp/d05_home.sh', pushed_files)
        events = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        elf_events = [e for e in events if e['event'] == 'fast_lifecycle_helpers_installed' and e.get('type') == 'native_static_elf']
        self.assertEqual(len(elf_events), 1)

    def test_wait_for_mode08_terminal_ui_dismisses_power_menu(self):
        calls = []
        async def fake_adb(*args, **kwargs):
            calls.append(args)
            return b''

        power_menu_rows = [{'text': 'Power off', 'desc': '', 'bounds': '[0,0][100,100]'}]
        valid_mode08_rows = [
            {'text': 'Service Recipes', 'desc': '', 'bounds': '[0,0][100,100]'},
            {'text': 'TID $01', 'desc': '', 'bounds': '[0,100][100,200]'}
        ]
        poll_count = 0
        async def fake_poll():
            nonlocal poll_count
            poll_count += 1
            if poll_count == 1:
                return power_menu_rows
            return valid_mode08_rows

        with self._patch_out(), patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'poll_current_ui_rows', fake_poll):
            rows = asyncio.run(CTRL.wait_for_mode08_terminal_ui(timeout=5))

        self.assertEqual(rows, valid_mode08_rows)
        # Verify BACK keyevent was sent to dismiss the power menu
        keyevent_calls = [c for c in calls if c and c[:3] == ('shell', 'input', 'keyevent') and c[3] == '4']
        self.assertEqual(len(keyevent_calls), 1)
        events = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        self.assertIn('dismissing_power_menu_dialog', [e['event'] for e in events])

    def test_case_verifies_genuine_sleep_state(self):
        class MockRig:
            def __init__(self):
                self.target = None
                self.held = None
                self.release = None
                self.states = {}

            def arm(self, command):
                self.target = command
                loop = asyncio.get_running_loop()
                self.held = loop.create_future()
                self.release = asyncio.Event()
                self.held.set_result({'connection': 2, 'command': command})

        rig = MockRig()
        genuine_terminal_rows = [
            dict(text='', desc='Service Recipes & Active Diagnostics', enabled='true', bounds='[0,0][480,100]'),
            dict(text='', desc='MODE 08 NON-ACTUATING DISCOVERY', enabled='true', bounds='[0,100][480,200]'),
            dict(text='Mode 08 is not supported by this ECU', desc='', enabled='true', bounds='[0,200][480,300]'),
            dict(text='Discover Mode 08', desc='', enabled='true', clickable='true', bounds='[10,20][100,80]'),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            stdout = b''
            if 'dumpsys' in args and 'power' in args:
                stdout = b'mWakefulness=Asleep mLastSleepTime=123456'
            elif 'dumpsys' in args and 'activity' in args:
                stdout = b'Stack #0: type=home com.android.launcher3/.Launcher'
            return SimpleNamespace(returncode=0, stdout=stdout, stderr=b'') if full else stdout

        async def fake_dump(label, screenshot=True, prepare=True):
            return genuine_terminal_rows

        async def fake_find_text(text, exact=False, scroll=True):
            node = dict(text=text, desc='', bounds='[10,20][100,80]')
            return (node, 50, 50), 0

        async def fake_launch_app(is_resume=False):
            pass

        async def fake_wake_and_unlock():
            pass

        async def fake_actual_os_snapshot(label):
            pass

        async def fake_wait_for_mode08_terminal_ui(timeout=30):
            return genuine_terminal_rows

        async def instant_sleep(_delay):
            pass

        with self._patch_out(), \
             patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'dump', fake_dump), \
             patch.object(CTRL, 'find_text', fake_find_text), \
             patch.object(CTRL, 'launch_app', fake_launch_app), \
             patch.object(CTRL, 'wake_and_unlock', fake_wake_and_unlock), \
             patch.object(CTRL, 'wait_for_mode08_terminal_ui', fake_wait_for_mode08_terminal_ui), \
             patch.object(CTRL, 'actual_os_snapshot', fake_actual_os_snapshot), \
             patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.case(rig, 2, 'Discover Mode 08'))

        lines = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        os_cmd_events = [e for e in lines if e['event'] == 'os_command_executed_during_hold']
        self.assertEqual(len(os_cmd_events), 1)
        self.assertEqual(os_cmd_events[0]['action'], 'SLEEP')
        self.assertEqual(os_cmd_events[0]['verified_state'], 'wakefulness_asleep')

    def test_case_fails_if_os_command_times_out(self):
        class MockRig:
            def __init__(self):
                self.target = None
                self.held = None
                self.release = None
                self.states = {}

            def arm(self, command):
                self.target = command
                loop = asyncio.get_running_loop()
                self.held = loop.create_future()
                self.release = asyncio.Event()
                self.held.set_result({'connection': 2, 'command': command})

        rig = MockRig()
        genuine_terminal_rows = [
            dict(text='Discover Mode 08', desc='', enabled='true', clickable='true', bounds='[10,20][100,80]'),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            if args and args[0] == 'shell' and len(args) > 1 and 'd05_home.sh' in str(args[1]):
                await asyncio.sleep(10.0)
            return b''

        async def fake_dump(label, screenshot=True, prepare=True):
            return genuine_terminal_rows

        async def fake_find_text(text, exact=False, scroll=True):
            node = dict(text=text, desc='', bounds='[10,20][100,80]')
            return (node, 50, 50), 0

        with self._patch_out(), \
             patch.object(CTRL, 'OS_COMMAND_HOLD_TIMEOUT', 0.05), \
             patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'dump', fake_dump), \
             patch.object(CTRL, 'find_text', fake_find_text):
            with self.assertRaisesRegex(RuntimeError, 'Native OS lifecycle command timed out'):
                asyncio.run(CTRL.case(rig, 1, 'Discover Mode 08'))

        lines = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        event_names = [e['event'] for e in lines]
        self.assertIn('os_command_timeout', event_names)
        self.assertNotIn('os_command_executed_during_hold', event_names)
        self.assertTrue(rig.release.is_set())

    def test_is_launcher_active_positive_and_negative(self):
        positives = [
            'mResumedActivity: ActivityRecord{f92e438 u0 com.android.launcher3/.Launcher t5}',
            'topResumedActivity=ActivityRecord{251038560 u0 com.google.android.apps.nexuslauncher/.NexusLauncherActivity t19}',
            'ResumedActivity: ActivityRecord{12345 u0 com.android.launcher3/.Launcher t1}',
            'Proc # 0: fore   T/A/TOP  trm: 0 2784:com.android.launcher3/u0a100 (top-activity)',
            'topDisplayFocusedStack=ActivityStack{d479a5e stackId=0 type=home mode=fullscreen visible=true translucent=false, 1 tasks}',
            'mHomeStack=ActivityStack{b398e3f stackId=0 type=home mode=fullscreen visible=true translucent=true, 1 tasks}',
            'Stack #0: type=home com.android.launcher3/.Launcher',
            'ACTIVITY com.android.launcher3/.uioverrides.QuickstepLauncher 8c728e pid=1892',
            'TASK com.android.launcher3 id=5',
        ]
        for p in positives:
            self.assertTrue(CTRL.is_launcher_active(p), f"Expected True for: {p}")

        negatives = [
            '',
            None,
            'mResumedActivity: ActivityRecord{a147202 u0 com.cbstudio.telltale/.MainActivity t6}',
            'mResumedActivity: ActivityRecord{a147202 u0 com.android.settings/.Settings t2}',
            'Stack #1: type=standard mode=fullscreen',
        ]
        for n in negatives:
            self.assertFalse(CTRL.is_launcher_active(n), f"Expected False for: {n}")

    def test_is_sleep_active_positive_and_negative(self):
        positives = [
            ('mWakefulness=Asleep\nmLastSleepTime=1000', 0),
            ('mWakefulness=Dozing\nmLastSleepTime=1000', 0),
            ('mWakefulness=Awake\nmLastSleepTime=2000', 1000),
            ('  mWakefulness=Asleep\n  mLastSleepReason=power_button', 0),
        ]
        for text, init in positives:
            self.assertTrue(CTRL.is_sleep_active(text, init), f"Expected True for: {text} with init={init}")

        negatives = [
            ('', 0),
            (None, 0),
            ('mWakefulness=Awake\nmLastSleepTime=1000', 1000),
            ('mWakefulness=Awake\nmLastSleepTime=0', 0),
        ]
        for text, init in negatives:
            self.assertFalse(CTRL.is_sleep_active(text, init), f"Expected False for: {text} with init={init}")

    def test_is_logcat_lifecycle_confirmed_home_and_sleep(self):
        home_log = (
            "1790012104.900  1948  1948 I SomeService: background log\n"
            "1790012105.017  1948  1967 I ActivityTaskManager: START u0 "
            "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher} from uid 0\n"
        )
        ok_home, ev_home = CTRL.is_logcat_lifecycle_confirmed(home_log, 'HOME', min_epoch_ts=1790012104.0)
        self.assertTrue(ok_home)
        self.assertTrue(any('category.HOME' in line for line in ev_home))

        sleep_log = (
            "1790012156.206  1948  2043 I PowerManagerService: Going to sleep due to power_button (uid 1000)...\n"
            "1790012156.230  1948  1983 I PowerManagerService: Sleeping (uid 1000)...\n"
        )
        ok_sleep, ev_sleep = CTRL.is_logcat_lifecycle_confirmed(sleep_log, 'SLEEP', min_epoch_ts=1790012155.0)
        self.assertTrue(ok_sleep)
        self.assertTrue(any('Going to sleep' in line for line in ev_sleep))

        neg_log = (
            "1790012104.900  1948  1948 I SomeService: background log\n"
            "1790012105.000  1948  1948 I ActivityTaskManager: START u0 {cmp=com.cbstudio.telltale/.MainActivity}\n"
        )
        ok_neg_h, _ = CTRL.is_logcat_lifecycle_confirmed(neg_log, 'HOME', min_epoch_ts=1790012104.0)
        self.assertFalse(ok_neg_h)
        ok_neg_s, _ = CTRL.is_logcat_lifecycle_confirmed(neg_log, 'SLEEP', min_epoch_ts=1790012104.0)
        self.assertFalse(ok_neg_s)

    def test_is_logcat_lifecycle_confirmed_epoch_timestamp_filtering(self):
        stale_log = (
            "1790012000.000  1948  1967 I ActivityTaskManager: START u0 "
            "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
        )
        # Stale log occurred at 1790012000, but baseline is 1790012100 -> must be rejected
        ok_stale, _ = CTRL.is_logcat_lifecycle_confirmed(stale_log, 'HOME', min_epoch_ts=1790012100.0)
        self.assertFalse(ok_stale)

        # Fresh log occurred at 1790012105 -> must be accepted
        fresh_log = (
            "1790012105.000  1948  1967 I ActivityTaskManager: START u0 "
            "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
        )
        ok_fresh, _ = CTRL.is_logcat_lifecycle_confirmed(fresh_log, 'HOME', min_epoch_ts=1790012100.0)
        self.assertTrue(ok_fresh)

    def test_is_logcat_lifecycle_confirmed_reviewer_counterexamples(self):
        baseline_ts = 1790012100.0

        # Counterexample 1: Baseline last line is already HOME (ts == baseline) -> must be rejected!
        boundary_equal_log = (
            "1790012100.000  1948  1967 I ActivityTaskManager: START u0 "
            "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
        )
        ok_equal, _ = CTRL.is_logcat_lifecycle_confirmed(boundary_equal_log, 'HOME', min_epoch_ts=baseline_ts)
        self.assertFalse(ok_equal, "Log with ts == baseline must not be confirmed as a fresh event")

        # Counterexample 2: HOME occurred 100ms before baseline (ts == baseline - 0.100) -> must be rejected!
        prior_100ms_log = (
            "1790012099.900  1948  1967 I ActivityTaskManager: START u0 "
            "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
        )
        ok_prior, _ = CTRL.is_logcat_lifecycle_confirmed(prior_100ms_log, 'HOME', min_epoch_ts=baseline_ts)
        self.assertFalse(ok_prior, "Log 100ms before baseline must not be confirmed")

        # Counterexample 3: Matching HOME line lacks epoch timestamp -> must be rejected!
        no_timestamp_log = (
            "I ActivityTaskManager: START u0 "
            "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
        )
        ok_no_ts, _ = CTRL.is_logcat_lifecycle_confirmed(no_timestamp_log, 'HOME', min_epoch_ts=baseline_ts)
        self.assertFalse(ok_no_ts, "Matching line without epoch timestamp must be rejected when baseline is set")

        # Counterexample 3B: Matching line lacks epoch timestamp (even with min_epoch_ts=0.0) -> must be rejected!
        ok_no_ts_zero, _ = CTRL.is_logcat_lifecycle_confirmed(no_timestamp_log, 'HOME', min_epoch_ts=0.0)
        self.assertFalse(ok_no_ts_zero, "Matching line without epoch timestamp must be rejected even with min_epoch_ts=0.0")

    def test_case_offset_based_isolation_prevents_cross_case_confirmation(self):
        with self._patch_out():
            logcat_path = self.out / 'android_logcat.txt'
            # 1. Simulate Case 1: writes HOME log into logcat
            case1_log = (
                "1790012105.017  1948  1967 I ActivityTaskManager: START u0 "
                "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
            )
            logcat_path.write_text(case1_log)
            case1_offset = CTRL.get_local_logcat_size()
            case1_ts = 1790012105.017

            # 2. Case 2 / Case 3 starts: records baseline offset and timestamp
            baseline_offset = case1_offset
            baseline_ts = case1_ts

            # Before any new log is produced in Case 2/3, offset reading yields empty string
            new_data = CTRL.read_recent_local_logcat(start_offset=baseline_offset)
            self.assertEqual(new_data, "")

            # Confirm that without new log, case cannot be confirmed
            confirmed, _ = CTRL.is_logcat_lifecycle_confirmed(new_data, 'HOME', min_epoch_ts=baseline_ts)
            self.assertFalse(confirmed)

            # Even if read without offset isolation (reading whole file), timestamp check rejects it
            confirmed_raw, _ = CTRL.is_logcat_lifecycle_confirmed(case1_log, 'HOME', min_epoch_ts=baseline_ts)
            self.assertFalse(confirmed_raw, "Dual layer defense: timestamp filtering must also reject Case 1 log")

            # 3. Simulate Case 3: Fresh HOME event appended after hold start
            case3_log = (
                "1790012200.500  1948  1967 I ActivityTaskManager: START u0 "
                "{act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher}\n"
            )
            with logcat_path.open('a') as f:
                f.write(case3_log)

            # Offset-based read returns ONLY the new line
            isolated_read = CTRL.read_recent_local_logcat(start_offset=baseline_offset)
            self.assertEqual(isolated_read, case3_log)
            self.assertNotIn("1790012105.017", isolated_read)

            # Confirmed with fresh line
            confirmed_fresh, ev = CTRL.is_logcat_lifecycle_confirmed(isolated_read, 'HOME', min_epoch_ts=baseline_ts)
            self.assertTrue(confirmed_fresh)
            self.assertTrue(any('1790012200.500' in line for line in ev))

    def test_read_recent_local_logcat_start_offset_isolation(self):
        with self._patch_out():
            logcat_path = self.out / 'android_logcat.txt'
            # Write initial historical logs
            logcat_path.write_text("1790010000.000 Initial historical log before hold\n")
            initial_offset = CTRL.get_local_logcat_size()
            self.assertGreater(initial_offset, 0)

            # Reading with start_offset = initial_offset should yield empty string (no new bytes yet)
            data_before = CTRL.read_recent_local_logcat(start_offset=initial_offset)
            self.assertEqual(data_before, "")

            # Append new log line generated after hold
            with logcat_path.open('a') as f:
                f.write("1790010001.000 Fresh event during hold\n")

            # Reading with start_offset = initial_offset should only return newly appended line
            data_after = CTRL.read_recent_local_logcat(start_offset=initial_offset)
            self.assertEqual(data_after, "1790010001.000 Fresh event during hold\n")
            self.assertNotIn("Initial historical log", data_after)

    def test_case_modified_option_b_fast_logcat_short_circuit(self):
        class MockRig:
            def __init__(self):
                self.target = None
                self.held = None
                self.release = None
                self.states = {}

            def arm(self, command):
                self.target = command
                loop = asyncio.get_running_loop()
                self.held = loop.create_future()
                self.release = asyncio.Event()
                self.held.set_result({'connection': 1, 'command': command})

        rig = MockRig()
        genuine_terminal_rows = [
            dict(text='Discover Mode 08', desc='', enabled='true', clickable='true', bounds='[10,20][100,80]'),
            dict(text='MODE 08 NON-ACTUATING DISCOVERY', desc='', enabled='true', bounds='[0,0][100,100]'),
            dict(text='TID $01', desc='', enabled='true', bounds='[0,100][100,200]'),
        ]

        logcat_calls = 0
        async def fake_adb(*args, timeout=40, check=True, full=False):
            nonlocal logcat_calls
            stdout = b''
            if 'logcat' in args:
                logcat_calls += 1
                if logcat_calls == 1:
                    # Baseline call before arming
                    stdout = b"1790012105.000  1948  1967 I System: baseline ready\n"
                else:
                    # Fresh event triggered by action during hold (strictly > baseline)
                    stdout = (
                        b"1790012105.500  1948  1967 I ActivityTaskManager: START u0 "
                        b"{act=android.intent.action.MAIN cat=[android.intent.category.HOME] "
                        b"cmp=com.android.launcher3/.Launcher} from uid 0\n"
                    )
            return SimpleNamespace(returncode=0, stdout=stdout, stderr=b'') if full else stdout

        async def fake_dump(label, screenshot=True, prepare=True):
            return genuine_terminal_rows

        async def fake_find_text(text, exact=False, scroll=True):
            node = dict(text=text, desc='', bounds='[10,20][100,80]')
            return (node, 50, 50), 0

        async def fake_launch_app(is_resume=False):
            pass

        async def fake_actual_os_snapshot(label):
            pass

        async def fake_wait_for_mode08_terminal_ui(timeout=30):
            return genuine_terminal_rows

        async def instant_sleep(_delay):
            pass

        with self._patch_out(), \
             patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'dump', fake_dump), \
             patch.object(CTRL, 'find_text', fake_find_text), \
             patch.object(CTRL, 'launch_app', fake_launch_app), \
             patch.object(CTRL, 'wait_for_mode08_terminal_ui', fake_wait_for_mode08_terminal_ui), \
             patch.object(CTRL, 'actual_os_snapshot', fake_actual_os_snapshot), \
             patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.case(rig, 1, 'Discover Mode 08'))

        lines = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        os_cmd_events = [e for e in lines if e['event'] == 'os_command_executed_during_hold']
        self.assertEqual(len(os_cmd_events), 1)
        ev = os_cmd_events[0]
        self.assertEqual(ev['action'], 'HOME')
        self.assertEqual(ev['verified_state'], 'activity_launcher')
        self.assertIn('verified_at_monotonic', ev)
        self.assertIn('hold_release_at_monotonic', ev)
        self.assertLess(ev['verified_at_monotonic'], ev['hold_release_at_monotonic'])
        self.assertGreater(ev['time_advance_ms'], 0)
        self.assertTrue(any('category.HOME' in e for e in ev['evidence']))

    def test_case_modified_option_b_host_monotonic_timestamps(self):
        class MockRig:
            def __init__(self):
                self.target = None
                self.held = None
                self.release = None
                self.states = {}

            def arm(self, command):
                self.target = command
                loop = asyncio.get_running_loop()
                self.held = loop.create_future()
                self.release = asyncio.Event()
                self.held.set_result({'connection': 2, 'command': command})

        rig = MockRig()
        genuine_terminal_rows = [
            dict(text='Discover Mode 08', desc='', enabled='true', clickable='true', bounds='[10,20][100,80]'),
            dict(text='MODE 08 NON-ACTUATING DISCOVERY', desc='', enabled='true', bounds='[0,0][100,100]'),
            dict(text='TID $01', desc='', enabled='true', bounds='[0,100][100,200]'),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            stdout = b''
            if 'dumpsys' in args and 'activity' in args:
                stdout = b'mResumedActivity: ActivityRecord{f92e438 u0 com.android.launcher3/.Launcher t5}'
            elif 'dumpsys' in args and 'power' in args:
                stdout = b'mWakefulness=Asleep mLastSleepReason=power_button'
            return SimpleNamespace(returncode=0, stdout=stdout, stderr=b'') if full else stdout

        async def fake_dump(label, screenshot=True, prepare=True):
            return genuine_terminal_rows

        async def fake_find_text(text, exact=False, scroll=True):
            node = dict(text=text, desc='', bounds='[10,20][100,80]')
            return (node, 50, 50), 0

        async def fake_launch_app(is_resume=False):
            pass

        async def fake_actual_os_snapshot(label):
            pass

        async def fake_wait_for_mode08_terminal_ui(timeout=30):
            return genuine_terminal_rows

        async def instant_sleep(_delay):
            pass

        with self._patch_out(), \
             patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'dump', fake_dump), \
             patch.object(CTRL, 'find_text', fake_find_text), \
             patch.object(CTRL, 'launch_app', fake_launch_app), \
             patch.object(CTRL, 'wait_for_mode08_terminal_ui', fake_wait_for_mode08_terminal_ui), \
             patch.object(CTRL, 'actual_os_snapshot', fake_actual_os_snapshot), \
             patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            asyncio.run(CTRL.case(rig, 1, 'Discover Mode 08'))

        lines = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        os_cmd_events = [e for e in lines if e['event'] == 'os_command_executed_during_hold']
        self.assertEqual(len(os_cmd_events), 1)
        ev = os_cmd_events[0]
        self.assertEqual(ev['action'], 'HOME')
        self.assertEqual(ev['verified_state'], 'activity_launcher')
        self.assertIn('verified_at_monotonic', ev)
        self.assertIn('hold_release_at_monotonic', ev)
        self.assertLess(ev['verified_at_monotonic'], ev['hold_release_at_monotonic'])
        self.assertGreater(ev['time_advance_ms'], 0)
        self.assertTrue(len(ev['evidence']) > 0)

        rel_events = [e for e in lines if e['event'] == 'mode08_hold_released_for_resume']
        self.assertEqual(len(rel_events), 1)
        rel_ev = rel_events[0]
        self.assertEqual(rel_ev['verified_at_monotonic'], ev['verified_at_monotonic'])
        self.assertEqual(rel_ev['hold_release_at_monotonic'], ev['hold_release_at_monotonic'])

    def test_case_fails_closed_when_hold_budget_expires_without_verification(self):
        class MockRig:
            def __init__(self):
                self.target = None
                self.held = None
                self.release = None
                self.states = {}

            def arm(self, command):
                self.target = command
                loop = asyncio.get_running_loop()
                self.held = loop.create_future()
                self.release = asyncio.Event()
                self.held.set_result({'connection': 2, 'command': command})

        rig = MockRig()
        genuine_terminal_rows = [
            dict(text='Discover Mode 08', desc='', enabled='true', clickable='true', bounds='[10,20][100,80]'),
        ]

        async def fake_adb(*args, timeout=40, check=True, full=False):
            return b'mResumedActivity: ActivityRecord{a147202 u0 com.cbstudio.telltale/.MainActivity t6}'

        async def fake_dump(label, screenshot=True, prepare=True):
            return genuine_terminal_rows

        async def fake_find_text(text, exact=False, scroll=True):
            node = dict(text=text, desc='', bounds='[10,20][100,80]')
            return (node, 50, 50), 0

        async def instant_sleep(_delay):
            pass

        with self._patch_out(), \
             patch.object(CTRL, 'adb', fake_adb), \
             patch.object(CTRL, 'dump', fake_dump), \
             patch.object(CTRL, 'find_text', fake_find_text), \
             patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            start_time = 100.0
            call_count = 0
            def mock_monotonic():
                nonlocal call_count
                call_count += 1
                return start_time + 0.5 * call_count

            with patch.object(CTRL.time, 'monotonic', mock_monotonic):
                with self.assertRaisesRegex(RuntimeError, 'Native OS lifecycle state transition not verified within hold budget'):
                    asyncio.run(CTRL.case(rig, 1, 'Discover Mode 08'))

        lines = [json.loads(l) for l in self.event_file.read_text().splitlines() if l.strip()]
        event_names = [e['event'] for e in lines]
        self.assertIn('mode08_hold_released_unverified', event_names)
        self.assertNotIn('os_command_executed_during_hold', event_names)
        self.assertTrue(rig.release.is_set())

    def test_read_recent_local_logcat_and_streaming_verification(self):
        with self._patch_out():
            # When file does not exist
            self.assertEqual(CTRL.read_recent_local_logcat(), "")

            # When file exists
            log_content = (
                "1790016000.100  1000  1010 I SomeTag: Normal message\n"
                "1790016001.250  1948  1967 I ActivityTaskManager: START u0 {act=android.intent.action.MAIN cat=[android.intent.category.HOME] cmp=com.android.launcher3/.Launcher} from uid 0\n"
            )
            (self.out / 'android_logcat.txt').write_text(log_content)
            recent = CTRL.read_recent_local_logcat()
            self.assertIn('ActivityTaskManager', recent)
            latest_ts = CTRL.get_latest_logcat_epoch_ts(recent)
            self.assertAlmostEqual(latest_ts, 1790016001.250)

            confirmed, evidence = CTRL.is_logcat_lifecycle_confirmed(recent, 'HOME', 1790016000.0)
            self.assertTrue(confirmed)
            self.assertTrue(any('Launcher' in e for e in evidence))

    def test_request_hierarchy_falls_back_to_sdcard_on_null_root(self):
        async def fake_adb(*args, timeout=45, check=True, full=False):
            if args[:3] == ('exec-out', 'uiautomator', 'dump'):
                res = SimpleNamespace(returncode=0, stdout=NULL_ROOT_STDERR.encode(), stderr=NULL_ROOT_STDERR.encode())
                return res if full else NULL_ROOT_STDERR.encode()
            if args[:2] == ('shell', 'rm'):
                return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''
            if args[:3] == ('shell', 'uiautomator', 'dump'):
                return SimpleNamespace(returncode=0, stdout=b'UI hierchary dumped to: /sdcard/window_dump.xml\n', stderr=b'') if full else b''
            if args[:2] == ('exec-out', 'cat'):
                return VALID_HIERARCHY
            return SimpleNamespace(returncode=0, stdout=b'', stderr=b'') if full else b''

        async def instant_sleep(_delay):
            pass

        with patch.object(CTRL, 'adb', fake_adb), patch.object(CTRL.asyncio, 'sleep', instant_sleep):
            xml, stderr, code, source = asyncio.run(CTRL.request_hierarchy())
            self.assertEqual(source, 'sdcard')
            self.assertEqual(xml, VALID_HIERARCHY)
            self.assertEqual(code, 0)


if __name__ == '__main__':
    unittest.main()


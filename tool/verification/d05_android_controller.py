#!/usr/bin/env python3
"""Bounded control of this CI job's disposable Android emulator and loopback rig.

Control JSON is read only from this project's explicit review branch. Operations
are an allowlist of UI inputs, observations and the three existing D05 cases.
No arbitrary shell, remote target, profile import, APK alteration or fake logcat.
"""
from __future__ import annotations
import asyncio
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path.cwd()
OUT = ROOT / 'd05-device'
sys.path.insert(0, str(ROOT / 'tool/obd_test_rig'))
from mode08_replay_reference import ReplayServer
SERIAL = 'emulator-5580'
PACKAGE = 'com.cbstudio.telltale'
CANDIDATE = 'acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e'
CONTROL_BRANCH = 'review/d05-android-execution-20260920'
CONTROL_PATH = 'tool/verification/d05_operator.json'
CONTROL_URL = ('https://gitlab.com/api/v4/projects/86385809/repository/files/' +
               urllib.parse.quote(CONTROL_PATH, safe='') + '/raw?ref=' +
               urllib.parse.quote(CONTROL_BRANCH, safe=''))
EVENT_FILE = OUT / 'controller.jsonl'
SEQ = 0
ACTIVE_RUN = None
DUMP_READY_SECONDS = 180
DUMP_RETRY_SLEEP = 3
TAP_SCROLL_ATTEMPTS = 12
# Right of the Dashboard tab ([0,684][96,752]) and left of vehicle-profile
# SeekBar thumbs (~146–241). Job 16609955129 chained 14 swipes at x=40
# (inside the Dashboard tab's x-range) with no gap; the merged gesture left
# Settings and the next dump was empty gauges. y stays above the tab bar
# (684) and the recorder strip.
LIST_FLING_X = 120
LIST_FLING_Y1 = 560
LIST_FLING_Y2 = 140
LIST_FLING_MS = 80
LIST_FLING_GAP_S = 0.08
FLINGS_PER_LOOK = 6
# ui_1843 SeekBar thumbs start around x=99. Job 16610532958 Petrol /
# drivetrain chips start at x=33. Focus left of both, above the tab bar.
LIST_FOCUS_X = 20
LIST_FOCUS_Y = 200
GUTTER_NUDGE_Y1 = 500
GUTTER_NUDGE_Y2 = 260
GUTTER_NUDGE_MS = 80
RECIPES_NEEDLES = (
    'Service Recipes',
    'Active Tests',
    'Service-Rezepte',
    '車行診斷配方',
)
RECIPES_RECOVERIES = 2
# Job 16610280973 dumped Settings *bottom* (Gauge style / Recommended
# adapter / licences) after the burst. Those rows are still the Settings
# list — Cluster/Minimal/Track there are style previews, not Dashboard.
SETTINGS_LIST_MARKERS = (
    'vehicle profile', 'fuel and drivetrain', 'diagnostic transcript',
    'service recipes', 'experimental', 'appearance',
    'what the adapter says', 'manual command',
    'gauge style', 'recommended adapter',
    'open source', 'licence', 'license',
    # Job 16610428447: PAGE_DOWN hid CONNECTION / VEHICLE PROFILE headers.
    # Mid-profile body + catalog CTA are still the Settings list. Do not
    # use the bare word "horsepower" — Dashboard recording copy mentions it.
    'horsepower, torque', 'official catalog',
    'volumetric efficiency', 'drag coefficient', 'rolling resistance',
    'air-fuel ratio', 'transmission efficiency', 'opening handshake',
)
ABOVE_RECIPES_MARKERS = (
    'vehicle profile', 'fuel and drivetrain', 'diagnostic transcript',
    'what the adapter says', 'manual command',
    'horsepower, torque', 'official catalog',
    'volumetric efficiency', 'air-fuel ratio', 'transmission efficiency',
    'opening handshake',
)
PAST_RECIPES_MARKERS = (
    'experimental', 'appearance', 'open-source', 'open source',
    'recommended', 'language /', 'gauge style', 'licence', 'license',
)
DRAWN_WAIT_SECONDS = 180
DRAWN_POLL_SLEEP = 2
REMOTE_DUMP = '/sdcard/d05_window.xml'
SCROLL_JAR_REMOTE = '/data/local/tmp/d05_scroll.jar'
SCROLL_JAVA = Path(__file__).resolve().parent / 'd05_scroll.java'
SCROLL_STUBS_DIR = Path(__file__).resolve().parent / 'd05_scroll_stubs'
SCROLL_NEEDLE_OK = re.compile(r'^[A-Za-z0-9 &._-]{1,80}$')
SCROLL_JAR_TRIED = False
SCROLL_JAR_USABLE = False
SDK_ROOT_FALLBACKS = (
    '/opt/android-sdk-linux',
    '/opt/android-sdk',
)
# Dashboard Mode 01 polls observed in job 16609802535. Never 08xx.
# Unknown 01 PIDs get a one-byte zero so NO DATA cannot yank the session
# during Settings → Recipes (job 16610137504).
MODE01_KEEPALIVE_PIDS = {
    '04': (0x00,),
    '05': (0x78,),
    '0B': (0x64,),
    '0C': (0x0C, 0x80),
    '0D': (0x00,),
    '0F': (0x3C,),
    '10': (0x00, 0x00),
    '11': (0x00,),
    '5E': (0x00, 0x00),
}
RESUMED_MARKERS = ('topResumedActivity', 'mFocusedApp=', 'mResumedActivity', 'ResumedActivity')
FOCUS_MARKERS = ('mCurrentFocus', 'mFocusedApp=')
WAKE_SOFT_TIMEOUT = 20
WAKE_KEYEVENT_DISABLED = False


def event(kind: str, **values):
    global SEQ
    SEQ += 1
    OUT.mkdir(exist_ok=True)
    data = dict(seq=SEQ, host_epoch_ns=time.time_ns(), host_monotonic_ns=time.monotonic_ns(),
                event=kind, run_id=ACTIVE_RUN, **values)
    with EVENT_FILE.open('a') as stream:
        stream.write(json.dumps(data, ensure_ascii=False) + '\n')
    print(json.dumps(data, ensure_ascii=False), flush=True)
    return data


def _timeout_bytes(value):
    if isinstance(value, (bytes, bytearray)):
        return bytes(value)
    if isinstance(value, str):
        return value.encode()
    return b''


async def adb(*args, timeout=40, check=True, full=False):
    command = ['adb', '-s', SERIAL, *[str(a) for a in args]]
    started = event('adb_start', argv=command)
    def run():
        return subprocess.run(command, capture_output=True, timeout=timeout)
    try:
        result = await asyncio.to_thread(run)
    except subprocess.TimeoutExpired as exc:
        stdout = _timeout_bytes(exc.stdout)
        stderr = _timeout_bytes(exc.stderr)
        event('adb_timeout', start_seq=started['seq'], timeout_seconds=timeout,
              stdout=stdout.decode(errors='replace')[:2000] if args[0] != 'exec-out' else '<binary-or-raw>',
              stderr=stderr.decode(errors='replace')[:1000])
        if check:
            raise
        result = subprocess.CompletedProcess(command, -1, stdout=stdout, stderr=stderr)
        return result if full else result.stdout
    event('adb_exit', start_seq=started['seq'], returncode=result.returncode,
          stdout=result.stdout.decode(errors='replace')[:2000] if args[0] != 'exec-out' else '<binary-or-raw>',
          stderr=result.stderr.decode(errors='replace')[:1000])
    if check and result.returncode:
        raise RuntimeError('ADB command failed: ' + ' '.join(map(str, args)))
    return result if full else result.stdout


def unique_name(label):
    if not re.fullmatch(r'[a-zA-Z0-9_-]{1,60}', label):
        raise ValueError('Invalid evidence label')
    return f'{SEQ:05d}_{label}'


def hierarchy_slice(xml):
    if not xml:
        raise ValueError('UI dump file was empty')
    start = xml.find(b'<?xml')
    if start < 0:
        start = xml.find(b'<hierarchy')
    if start < 0:
        raise ValueError('UI dump contained no XML hierarchy')
    end_tag = b'</hierarchy>'
    end = xml.find(end_tag, start)
    if end >= 0:
        return xml[start:end + len(end_tag)]
    hier = xml.find(b'<hierarchy', start)
    if hier >= 0:
        close = xml.find(b'/>', hier)
        next_child = xml.find(b'<', hier + 1)
        if close >= 0 and (next_child < 0 or close < next_child):
            return xml[start:close + 2]
    raise ValueError('UI dump hierarchy was truncated')


def parse_ui_rows(xml):
    root = ET.fromstring(hierarchy_slice(xml))
    if next(root.iter('node'), None) is None:
        raise ValueError('UI dump hierarchy had no nodes')
    return [dict(text=n.get('text'), desc=n.get('content-desc'), bounds=n.get('bounds'),
                 enabled=n.get('enabled'), clickable=n.get('clickable'), clazz=n.get('class'))
            for n in root.iter('node') if n.get('text') or n.get('content-desc') or n.get('class') == 'android.widget.EditText']


def activity_is_resumed(dumpsys_text, package=PACKAGE):
    for line in dumpsys_text.splitlines():
        if package not in line or 'MainActivity' not in line:
            continue
        if any(marker in line for marker in RESUMED_MARKERS):
            return True
    return False


def window_is_focused(dumpsys_text, package=PACKAGE):
    for line in dumpsys_text.splitlines():
        if package not in line or 'MainActivity' not in line:
            continue
        if any(marker in line for marker in FOCUS_MARKERS):
            return True
    return False


def interesting_state_lines(text, markers):
    rows = []
    for line in text.splitlines():
        stripped = line.strip()
        if any(marker in stripped for marker in markers):
            rows.append(stripped)
    return rows


def crash_lines(text):
    rows = []
    for line in text.splitlines():
        if any(token in line for token in ('FATAL EXCEPTION', 'AndroidRuntime', 'Process: ' + PACKAGE)):
            rows.append(line.strip())
    return rows[:12]


async def prepare_window(*, unlock_swipe=False):
    """Keep the display awake. Lock-screen swipe is opt-in: dump-time swipe
    dropped the live ELM TCP session after handshake (job 16609394827).
    """
    await adb('shell', 'settings', 'put', 'secure', 'lockscreen.disabled', '1',
              timeout=15, check=False)
    await adb('shell', 'svc', 'power', 'stayon', 'true', timeout=WAKE_SOFT_TIMEOUT, check=False)
    await adb('shell', 'wm', 'dismiss-keyguard', timeout=WAKE_SOFT_TIMEOUT, check=False)
    if not unlock_swipe:
        event('prepare_window_skip_swipe', reason='dump_path')
        return
    dumped = await adb('shell', 'dumpsys', 'window', 'windows', timeout=20, check=False)
    text = dumped.decode(errors='replace') if isinstance(dumped, (bytes, bytearray)) else str(dumped)
    if window_is_focused(text):
        event('prepare_window_skip_swipe', reason='already_focused')
        return
    await adb('shell', 'input', 'swipe', '240', '700', '240', '200', '250',
              timeout=15, check=False)


async def wake_and_unlock():
    global WAKE_KEYEVENT_DISABLED
    await prepare_window()
    if not WAKE_KEYEVENT_DISABLED:
        result = await adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP',
                           timeout=WAKE_SOFT_TIMEOUT, check=False, full=True)
        if result.returncode == -1:
            WAKE_KEYEVENT_DISABLED = True
            event('wake_keyevent_skipped', reason='timeout')


async def wait_for_drawn_window(timeout=None):
    """Activity resume is not a first frame. Job 16608891761 dumped while
    Flutter was still extracting kernel_blob.bin and reporting Width is zero;
    Fully drawn arrived at +104s. Wait for that mark, then still try dump.
    """
    timeout = DRAWN_WAIT_SECONDS if timeout is None else timeout
    deadline = time.monotonic() + timeout
    last = ''
    while True:
        logs = await adb('logcat', '-d', '-t', '120', timeout=15, check=False)
        last = logs.decode(errors='replace') if isinstance(logs, (bytes, bytearray)) else str(logs)
        if f'Fully drawn {PACKAGE}' in last:
            event('app_fully_drawn', package=PACKAGE)
            return
        if time.monotonic() >= deadline:
            event('app_not_fully_drawn', logcat_tail=last[-1500:])
            return
        await asyncio.sleep(DRAWN_POLL_SLEEP)


async def wait_for_resumed_activity(timeout=45):
    deadline = time.monotonic() + timeout
    next_wake = 0.0
    last = ''
    while time.monotonic() < deadline:
        dumped = await adb('shell', 'dumpsys', 'activity', 'activities', timeout=20, check=False)
        last = dumped.decode(errors='replace')
        if activity_is_resumed(last):
            event('app_window_resumed', package=PACKAGE)
            return
        now = time.monotonic()
        if now >= next_wake:
            await prepare_window()
            next_wake = now + 5
        await asyncio.sleep(0.5)
    event('app_window_not_resumed', package=PACKAGE, dumpsys_tail=last[-1500:])
    raise RuntimeError('MainActivity did not reach a resumed window')


async def wait_for_focused_window(timeout=30):
    deadline = time.monotonic() + timeout
    last = ''
    while time.monotonic() < deadline:
        dumped = await adb('shell', 'dumpsys', 'window', 'windows', timeout=20, check=False)
        last = dumped.decode(errors='replace')
        if window_is_focused(last):
            event('app_window_focused', package=PACKAGE)
            return True
        await prepare_window()
        await asyncio.sleep(0.5)
    event('app_window_not_focused', package=PACKAGE, dumpsys_tail=last[-1500:])
    return False


async def launch_app():
    await wake_and_unlock()
    await adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/.MainActivity',
              '-f', '0x10000000', timeout=60)
    await wait_for_resumed_activity()
    await wait_for_focused_window()
    await wait_for_drawn_window()


async def request_hierarchy():
    dumped = await adb('exec-out', 'uiautomator', 'dump', '/dev/tty', timeout=45, check=False, full=True)
    xml = dumped.stdout or b''
    stderr = dumped.stderr.decode(errors='replace')
    source = 'exec-out-tty'
    has_xml = b'<hierarchy' in xml or b'<?xml' in xml
    saw_null_root = b'null root node' in xml or 'null root node' in stderr
    if has_xml or xml or saw_null_root:
        return xml, stderr, dumped.returncode, source
    await adb('shell', 'rm', '-f', REMOTE_DUMP, check=False)
    file_dump = await adb('shell', 'uiautomator', 'dump', REMOTE_DUMP, timeout=45, check=False, full=True)
    xml = await adb('exec-out', 'cat', REMOTE_DUMP, check=False)
    extra = file_dump.stderr.decode(errors='replace')
    if extra:
        stderr = (stderr + '\n' + extra).strip()
    return xml, stderr, file_dump.returncode, 'sdcard'


async def capture_dump_failure_evidence(label, xml):
    name = unique_name(label + '_diag')
    OUT.mkdir(exist_ok=True)
    (OUT / (name + '_raw.bin')).write_bytes(xml)
    blobs = {}
    for service, args in (
        ('activity', ('shell', 'dumpsys', 'activity', 'activities')),
        ('window', ('shell', 'dumpsys', 'window', 'windows')),
        ('power', ('shell', 'dumpsys', 'power')),
    ):
        data = await adb(*args, timeout=20, check=False)
        blobs[service] = data.decode(errors='replace')
        path = OUT / f'{name}_{service}.txt'
        path.write_bytes(data)
        event('dump_failure_state', service=service, file=path.name, sha256=hashlib.sha256(data).hexdigest())
    logcat = await adb('logcat', '-d', '-t', '160', timeout=20, check=False)
    blobs['logcat'] = logcat.decode(errors='replace')
    (OUT / f'{name}_logcat.txt').write_bytes(logcat)
    event('dump_failure_logcat', file=name + '_logcat.txt', sha256=hashlib.sha256(logcat).hexdigest(),
          fatal=any(token in blobs['logcat'] for token in ('FATAL EXCEPTION', 'AndroidRuntime')))
    resume = interesting_state_lines(blobs['activity'], RESUMED_MARKERS + ('mCurrentFocus',))
    focus = interesting_state_lines(blobs['window'], FOCUS_MARKERS)
    power = interesting_state_lines(blobs['power'], ('mWakefulness', 'mHoldingDisplaySuspendBlocker'))
    crashes = crash_lines(blobs['logcat'])
    return {
        'raw_sha256': hashlib.sha256(xml).hexdigest(),
        'raw_len': len(xml),
        'raw_head_hex': xml[:64].hex(),
        'resumed': resume[:8],
        'focused': focus[:8],
        'power': power[:8],
        'crashes': crashes,
    }


async def dump(label='view', screenshot=True, prepare=True):
    name = unique_name(label)
    deadline = time.monotonic() + DUMP_READY_SECONDS
    last_error = None
    attempt = 0
    xml = b''
    stderr = ''
    source = ''
    returncode = 0
    while True:
        attempt += 1
        if prepare:
            await prepare_window()
        xml, stderr, returncode, source = await request_hierarchy()
        try:
            rows = parse_ui_rows(xml)
            break
        except (ET.ParseError, ValueError) as exc:
            last_error = exc
            OUT.mkdir(exist_ok=True)
            (OUT / f'{name}_unusable_{attempt}.xml').write_bytes(xml)
            event('ui_dump_unusable', attempt=attempt, error=type(exc).__name__ + ': ' + str(exc),
                  dump_returncode=returncode, dump_stderr=stderr[:300], xml_len=len(xml),
                  dump_source=source)
            if time.monotonic() >= deadline:
                (OUT / (name + '.xml')).write_bytes(xml)
                diagnosis = await capture_dump_failure_evidence(label, xml)
                event('ui_dump_exhausted', attempts=attempt, diagnosis=diagnosis)
                raise RuntimeError(
                    f'UI hierarchy dump stayed empty after {attempt} attempts: {last_error}; '
                    f'source={source} xml_len={len(xml)} raw_head_hex={diagnosis["raw_head_hex"]} '
                    f'resumed={diagnosis["resumed"]} focused={diagnosis["focused"]} '
                    f'power={diagnosis["power"]} crashes={diagnosis["crashes"]}'
                ) from last_error
            await asyncio.sleep(DUMP_RETRY_SLEEP)
    OUT.mkdir(exist_ok=True)
    (OUT / (name + '.xml')).write_bytes(xml)
    print('DEVICE_UI ' + json.dumps(rows, ensure_ascii=False), flush=True)
    if screenshot:
        image = await adb('exec-out', 'screencap', '-p', timeout=45)
        if not image.startswith(b'\x89PNG\r\n\x1a\n'):
            raise ValueError('screencap did not produce a PNG')
        path = OUT / (name + '.png')
        with path.open('xb') as file:
            file.write(image)
        event('screenshot_captured', file=path.name, sha256=hashlib.sha256(image).hexdigest(),
              xml_file=name + '.xml', xml_sha256=hashlib.sha256(xml).hexdigest())
    return rows


def bounds(row):
    values = [int(i) for i in re.findall(r'\d+', row['bounds'] or '')]
    if len(values) != 4:
        raise ValueError('Unparseable node bounds')
    x1, y1, x2, y2 = values
    if not (0 <= x1 < x2 <= 480 and 0 <= y1 < y2 <= 800):
        raise ValueError('Node not visible on the fixed 480x800 emulator')
    return x1, y1, x2, y2


def node_labels(row):
    return [row.get('text') or '', row.get('desc') or '']


def node_primary_label(row):
    """First non-empty line of text or content-desc. Flutter leaves text empty."""
    for value in node_labels(row):
        first = value.split('\n', 1)[0].strip()
        if first:
            return first
    return ''


def node_matches(row, text, exact=False):
    """Match visible text or content-desc.

    Flutter semantics put the title on the first line and extra context after
    a newline (Settings\\nTab 5 of 5). Substring-anywhere also hits Connect's
    'Full disclosure in Settings', so non-exact matches require the first line
    to equal or start with the query.
    """
    if row.get('enabled') != 'true':
        return False
    labels = node_labels(row)
    if exact:
        return any(value == text for value in labels)
    needle = text.lower()
    for value in labels:
        first = value.split('\n', 1)[0].lower()
        if first == needle or first.startswith(needle):
            return True
    return False


def locate_text(rows, text, exact=False):
    matching = []
    for row in rows:
        if not node_matches(row, text, exact):
            continue
        try:
            x1, y1, x2, y2 = bounds(row)
        except ValueError:
            continue
        area = (x2 - x1) * (y2 - y1)
        clickable = 0 if row.get('clickable') == 'true' else 1
        matching.append((clickable, area, row, (x1 + x2) // 2, (y1 + y2) // 2))
    if not matching:
        return None
    _, _, row, x, y = min(matching)
    return row, x, y


def dashboard_ready(rows):
    """Bottom tabs mean handshake left the last-adapter / Connect home."""
    return (locate_text(rows, 'Settings') is not None or
            locate_text(rows, 'Dashboard') is not None)


def is_recipes_query(text):
    first = (text or '').split('\n', 1)[0].strip().lower()
    return first.startswith('service recipe') or first.startswith('active test')


def mode01_keepalive_line(compact, headers=False, spaces=True):
    """Answer dashboard Mode 01 polls. None means use the Mode 08 fixture path.

    Job 16609802535 polled 015E/010C/… with immediate NO DATA, then ATRV,
    then reference_disconnect while Settings was still above Service Recipes.
    Job 16610137504 reached the recipes tile via scrollIntoView, then the
    client still closed. Unknown 01 PIDs get a one-byte zero. Never 08xx.
    ATRV / 0100 stay on ReplayServer.
    """
    if not compact or compact.startswith('AT') or compact.startswith('08'):
        return None
    if compact.startswith('0100') or not compact.startswith('01') or len(compact) < 4:
        return None
    body = compact[2:]
    if len(body) % 2:
        body = body[:-1]
    if not body or any(ch not in '0123456789ABCDEF' for ch in body):
        return None
    payload = [0x41]
    matched = False
    for i in range(0, len(body), 2):
        pid = body[i:i + 2]
        data = MODE01_KEEPALIVE_PIDS.get(pid, (0x00,))
        matched = True
        payload.append(int(pid, 16))
        payload.extend(data)
    if not matched:
        return None
    tokens = [f'{byte:02X}' for byte in payload]
    if headers:
        tokens = ['7E8', f'{len(payload):02X}'] + tokens
    return ' '.join(tokens) if spaces else ''.join(tokens)


def first_line_values(rows):
    lines = []
    for row in rows:
        for value in node_labels(row):
            if value:
                lines.append(value.split('\n', 1)[0])
    return lines


def recipe_test_labels(rows):
    """Raw text/desc that mention Recipe or Test — matcher diagnostics."""
    hits = []
    for row in rows:
        for value in node_labels(row):
            low = value.lower()
            if 'recipe' in low or ('test' in low and 'road test' not in low):
                hits.append(value[:240])
    return hits


def session_dropped(rows):
    """Connect home or the adapter-dropped sheet — not a Settings list."""
    if locate_text(rows, 'Dashboard') is not None and locate_text(rows, 'Settings') is not None:
        if settings_list_open(rows):
            return False
        # Tabs still present: residency / dashboard_surface handles this.
        if not any('stopped responding' in line.lower() or 'has been dropped' in line.lower()
                   for line in first_line_values(rows)):
            return False
    if locate_text(rows, 'Choose a connection') is not None:
        return locate_text(rows, 'Settings') is None or locate_text(rows, 'Dashboard') is None
    return any('stopped responding' in line.lower() or 'has been dropped' in line.lower()
               for line in first_line_values(rows))


def visible_seekbars(rows):
    """On-screen SeekBar thumbs (ignore [0,0] off-screen Flutter leftovers)."""
    found = []
    for row in rows:
        if row.get('clazz') != 'android.widget.SeekBar':
            continue
        try:
            x1, y1, x2, y2 = bounds(row)
        except ValueError:
            continue
        if x2 <= x1 or y2 <= y1:
            continue
        found.append((row, x1, y1, x2, y2))
    return found


def point_hits_seekbar(x, y, rows):
    for _row, x1, y1, x2, y2 in visible_seekbars(rows):
        if x1 <= x <= x2 and y1 <= y <= y2:
            return True
    return False


def _is_tab_row(row):
    for value in node_labels(row):
        first = value.split('\n', 1)[0].strip().lower()
        if 'tab' in value.lower() and first in (
            'dashboard', 'pid', 'fault codes', 'timing', 'settings',
        ):
            return True
    return False


def interactive_rects(rows):
    """SeekBars and non-tab chips that steal PAGE_DOWN / focus taps."""
    found = list(visible_seekbars(rows))
    for row in rows:
        if row.get('clickable') != 'true' or _is_tab_row(row):
            continue
        try:
            x1, y1, x2, y2 = bounds(row)
        except ValueError:
            continue
        if x2 <= x1 or y2 <= y1 or y1 >= 650:
            continue
        found.append((row, x1, y1, x2, y2))
    return found


def point_hits_interactive(x, y, rows):
    for _row, x1, y1, x2, y2 in interactive_rects(rows):
        if x1 <= x <= x2 and y1 <= y <= y2:
            return True
    return False


def dump_fingerprint(rows):
    """Stable identity of the Settings list viewport (labels + bounds)."""
    parts = []
    for row in rows:
        if _is_tab_row(row):
            continue
        labels = [value for value in node_labels(row) if value]
        if not labels:
            continue
        first = labels[0].split('\n', 1)[0].strip()[:80]
        parts.append((first, row.get('bounds') or ''))
    return tuple(parts)


def settings_list_open(rows):
    """Settings *list*, not merely the Settings\\nTab 5 of 5 destination.

    Job 16609955129 dumped Dashboard gauges after the burst while that tab
    was still in the tree. CONNECTION / the non-tab Settings title are the
    residency signal. Job 16610280973 then sat on Gauge style / licences
    (Settings bottom) and dashboard_surface treated both tabs as Dashboard.
    Job 16610428447: one PAGE_DOWN hid those headers and left Horsepower
    body + catalog + SeekBars (ui_1843). That is still the list — retapping
    the already-selected Settings tab does not scroll and stops paging.
    """
    for row in rows:
        for value in node_labels(row):
            first = value.split('\n', 1)[0].strip()
            low = first.lower()
            if low == 'settings' and 'tab' not in value.lower():
                return True
            if low in ('connection', 'disconnect'):
                return True
            if any(token in low for token in SETTINGS_LIST_MARKERS):
                return True
    if locate_text(rows, 'Settings') is not None and visible_seekbars(rows):
        return True
    return False


def dashboard_surface(rows):
    """Gauge grid / 'No data — Unverified' without the Settings list.

    Both tabs alone are not Dashboard: Settings mid-profile (job 16610428447
    ui_1843) and Settings bottom keep Dashboard + Settings tabs. Only the
    unverified / stale gauge strip counts.
    """
    if settings_list_open(rows) or session_dropped(rows):
        return False
    for line in first_line_values(rows):
        low = line.lower()
        # Job 16610702070 looks 9-12 sat on Dashboard "Road test started"
        # while hunting recipes; 'unverified' was absent so residency never
        # retapped Settings. The recipes tile then appeared in a later dump.
        if 'no data' in low or 'unverified' in low or 'road test' in low:
            return True
    return False


def still_above_recipes(rows):
    return any(any(token in line.lower() for token in ABOVE_RECIPES_MARKERS)
               for line in first_line_values(rows))


def past_recipes(rows):
    """Overshot the tile into Experimental / Gauge style / licences."""
    if locate_text(rows, 'Settings') is None:
        return False
    return any(any(token in line.lower() for token in PAST_RECIPES_MARKERS)
               for line in first_line_values(rows))


def locate_recipes(rows):
    """Prefer the Settings tile title with real visible bounds.

    Flutter semantics put 'Service Recipes & Active Tests' on content-desc and
    leave text empty. Do not tap a parent with empty text and empty desc even
    if it covers the tile (job 16610137504 / 16610702070).
    """
    titled = []
    fallback = []
    needles = tuple(needle.lower() for needle in RECIPES_NEEDLES)
    for row in rows:
        if row.get('enabled') != 'true':
            continue
        label = node_primary_label(row)
        if not label:
            continue
        try:
            x1, y1, x2, y2 = bounds(row)
        except ValueError:
            continue
        area = (x2 - x1) * (y2 - y1)
        clickable = 0 if row.get('clickable') == 'true' else 1
        item = (clickable, area, row, (x1 + x2) // 2, (y1 + y2) // 2)
        low = label.lower()
        if any(low == needle or low.startswith(needle) for needle in needles):
            titled.append(item)
        elif 'recipe' in low or 'active test' in low or 'service-rezepte' in low:
            fallback.append(item)
    matching = titled or fallback
    if not matching:
        return None
    _, _, row, x, y = min(matching)
    return row, x, y


def _sdk_roots():
    roots = []
    seen = set()
    for raw in (
        os.environ.get('ANDROID_HOME'),
        os.environ.get('ANDROID_SDK_ROOT'),
        *SDK_ROOT_FALLBACKS,
        str(Path.home() / 'Android' / 'Sdk'),
    ):
        if not raw:
            continue
        path = Path(raw)
        try:
            key = str(path.resolve()) if path.exists() else str(path)
        except OSError:
            key = str(path)
        if key in seen:
            continue
        seen.add(key)
        roots.append(path)
    return roots


def _jar_has_class_files(path):
    """True when the jar has javac .class files, not a device DEX wrapper.

    Job 16610137504 pulled /system/framework/uiautomator.jar (classes.dex only).
    javac then failed with package com.android.uiautomator.core does not exist.
    """
    try:
        with zipfile.ZipFile(path) as archive:
            return any(name.endswith('.class') for name in archive.namelist())
    except (OSError, zipfile.BadZipFile):
        return False


def _android_jar():
    jars = []
    for root in _sdk_roots():
        platforms = root / 'platforms'
        preferred = platforms / 'android-29' / 'android.jar'
        if preferred.is_file():
            return preferred
        if platforms.is_dir():
            jars.extend(sorted(platforms.glob('android-*/android.jar')))
    return jars[-1] if jars else None


def _host_uiautomator_jar():
    """SDK stub jar with Java classes. Device DEX is never a compile classpath."""
    found = []
    for root in _sdk_roots():
        platforms = root / 'platforms'
        preferred = platforms / 'android-23' / 'uiautomator.jar'
        if preferred.is_file():
            found.append(preferred)
        if platforms.is_dir():
            found.extend(sorted(platforms.glob('android-*/uiautomator.jar')))
        tools = root / 'tools' / 'lib' / 'uiautomator.jar'
        if tools.is_file():
            found.append(tools)
    for jar in found:
        if _jar_has_class_files(jar):
            return jar
    return None


def _javac():
    found = shutil.which('javac')
    if found:
        return found
    home = os.environ.get('JAVA_HOME')
    if home:
        candidate = Path(home) / 'bin' / 'javac'
        if candidate.is_file():
            return str(candidate)
    return None


def _dexer():
    for root in _sdk_roots():
        build_tools = root / 'build-tools'
        if not build_tools.is_dir():
            continue
        d8s = sorted(build_tools.glob('*/d8'))
        if d8s:
            return 'd8', str(d8s[-1])
        dxs = sorted(build_tools.glob('*/dx'))
        if dxs:
            return 'dx', str(dxs[-1])
    d8 = shutil.which('d8')
    if d8:
        return 'd8', d8
    dx = shutil.which('dx')
    if dx:
        return 'dx', dx
    return None


def _materialize_uiautomator_stubs(dest):
    sources = sorted(SCROLL_STUBS_DIR.rglob('*.java'))
    if not sources:
        raise RuntimeError('D05 uiautomator compile stubs are missing')
    written = []
    for src in sources:
        rel = src.relative_to(SCROLL_STUBS_DIR)
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(src.read_text(encoding='utf-8'), encoding='utf-8')
        written.append(target)
    return written


class ScrollJarUnusable(RuntimeError):
    """Compile/push failed. Fail closed — do not PAGE_DOWN until the job times out."""


def _raise_scroll_jar_unusable(**values):
    event('scroll_jar_unusable', **values)
    reason = values.get('reason') or values.get('error') or 'unavailable'
    raise ScrollJarUnusable(
        'D05 scroll jar is not usable (' + str(reason) +
        '); refusing to skip into PAGE_DOWN/timeout'
    )


async def ensure_scroll_jar():
    """Build D05Scroll against host android.jar + Java uiautomator stubs.

    Jobs 16610137504 / 16610280973: javac -cp device DEX uiautomator.jar cannot
    see com.android.uiautomator.core. Host platforms/android-29 has android.jar
    but not uiautomator.jar (removed after API 23). Compile-only stubs satisfy
    javac; runtime classes come from the emulator. Missing javac / android.jar
    / dexer fails with scroll_jar_unusable instead of a silent skip.
    """
    global SCROLL_JAR_TRIED, SCROLL_JAR_USABLE
    if SCROLL_JAR_TRIED:
        if not SCROLL_JAR_USABLE:
            _raise_scroll_jar_unusable(reason='not_usable')
        return True
    SCROLL_JAR_TRIED = True
    SCROLL_JAR_USABLE = False
    try:
        work = OUT / 'scroll-build'
        work.mkdir(parents=True, exist_ok=True)
        android_jar = _android_jar()
        javac = _javac()
        dexer = _dexer()
        host_uia = _host_uiautomator_jar()
        if not SCROLL_JAVA.is_file():
            _raise_scroll_jar_unusable(reason='missing_source',
                                       path=str(SCROLL_JAVA))
        if not javac:
            _raise_scroll_jar_unusable(reason='missing_javac')
        if not android_jar:
            _raise_scroll_jar_unusable(
                reason='missing_android_jar',
                sdk_roots=[str(root) for root in _sdk_roots()],
            )
        if not dexer:
            _raise_scroll_jar_unusable(reason='missing_dexer',
                                       android_jar=str(android_jar))
        source = work / 'D05Scroll.java'
        source.write_text(SCROLL_JAVA.read_text(encoding='utf-8'))
        classpath = [str(android_jar)]
        extra_sources = []
        # Host platforms/android-23 uiautomator.jar pulls junit.framework.TestCase
        # (job 16610975186 javac_failed). Compile-only stubs do not.
        stub_kind = 'compile_stubs'
        extra_sources = _materialize_uiautomator_stubs(work / 'stubs')
        event('scroll_jar_using_compile_stubs',
              files=[str(path.relative_to(work / 'stubs')) for path in extra_sources],
              ignored_host_uiautomator=str(host_uia) if host_uia else None)
        cp = ':'.join(classpath)
        javac_cmds = (
            [javac, '--release', '8', '-cp', cp, '-d', str(work),
             str(source), *[str(path) for path in extra_sources]],
            [javac, '-source', '8', '-target', '8', '-bootclasspath', str(android_jar),
             '-cp', cp, '-d', str(work), str(source),
             *[str(path) for path in extra_sources]],
        )
        compiled = None
        classfile = work / 'D05Scroll.class'
        for argv in javac_cmds:
            compiled = await asyncio.to_thread(
                subprocess.run, argv, capture_output=True, timeout=60,
            )
            if compiled.returncode == 0 and classfile.is_file():
                break
        if compiled is None or compiled.returncode or not classfile.is_file():
            _raise_scroll_jar_unusable(
                reason='javac_failed',
                android_jar=str(android_jar),
                uiautomator=str(host_uia) if host_uia else stub_kind,
                stderr=(compiled.stderr.decode(errors='replace')[:1500] if compiled else ''),
            )
        kind, tool = dexer
        jar_out = work / 'd05_scroll.jar'
        if kind == 'dx':
            dexed = await asyncio.to_thread(
                subprocess.run,
                [tool, '--dex', '--output', str(jar_out), str(classfile)],
                capture_output=True, timeout=60,
            )
        else:
            dexed = await asyncio.to_thread(
                subprocess.run,
                [tool, '--lib', str(android_jar), '--output', str(jar_out), str(classfile)],
                capture_output=True, timeout=60,
            )
            if not jar_out.is_file():
                dex = work / 'classes.dex'
                if dex.is_file():
                    with zipfile.ZipFile(jar_out, 'w') as archive:
                        archive.write(dex, 'classes.dex')
        if not jar_out.is_file():
            _raise_scroll_jar_unusable(
                reason='dex_failed',
                stderr=dexed.stderr.decode(errors='replace')[:1500],
            )
        pushed = await adb('push', str(jar_out), SCROLL_JAR_REMOTE,
                           timeout=20, check=False, full=True)
        if getattr(pushed, 'returncode', 1):
            _raise_scroll_jar_unusable(
                reason='push_failed',
                returncode=getattr(pushed, 'returncode', None),
                stderr=(getattr(pushed, 'stderr', b'') or b'').decode(errors='replace')[:500],
            )
        event('scroll_jar_ready', remote=SCROLL_JAR_REMOTE, stubs=stub_kind,
              android_jar=str(android_jar),
              sha256=hashlib.sha256(jar_out.read_bytes()).hexdigest())
        SCROLL_JAR_USABLE = True
        return True
    except ScrollJarUnusable:
        SCROLL_JAR_USABLE = False
        raise
    except Exception as exc:
        SCROLL_JAR_USABLE = False
        _raise_scroll_jar_unusable(reason='compile_failed',
                                   error=type(exc).__name__ + ': ' + str(exc))


async def scroll_into_view(needle):
    """UiAutomator scrollIntoView. Fail closed if the jar did not compile.

    Device DEX cannot satisfy javac (job 16610280973). A silent skip plus
    PAGE_DOWN then timed out job 16610702070. Never runtest a missing jar.
    """
    if not isinstance(needle, str) or not SCROLL_NEEDLE_OK.fullmatch(needle):
        raise ValueError('Invalid scroll needle')
    await ensure_scroll_jar()
    if not SCROLL_JAR_USABLE:
        _raise_scroll_jar_unusable(reason='not_usable', needle=needle)
    event('uiautomator_scroll_into_view', needle=needle)
    await adb('shell', 'uiautomator', 'runtest', SCROLL_JAR_REMOTE, '-c', 'D05Scroll',
              '-e', 'needle', needle, timeout=60, check=False)
    return True


async def fling_list(count=1, upward=False):
    """Fling the Settings ListView without hitting sliders or the tab bar.

    count>1 is one adb shell. A short sleep between swipes keeps them from
    merging into a down-stroke onto the Dashboard tab (job 16609955129).
    """
    if count < 1:
        return
    # Job 16609955129 stayed on Export transcript for every locate dump:
    # 80ms gutter flings did not move the outer Settings list. PAGE_DOWN
    # targets the focused scrollable instead of the transcript Panel.
    if not upward:
        for _ in range(max(1, count // 2)):
            await adb('shell', 'input', 'keyevent', 'KEYCODE_PAGE_DOWN',
                      timeout=8, check=False)
    y1, y2 = (LIST_FLING_Y2, LIST_FLING_Y1) if upward else (LIST_FLING_Y1, LIST_FLING_Y2)
    if count == 1:
        await adb('shell', 'input', 'swipe', LIST_FLING_X, y1,
                  LIST_FLING_X, y2, LIST_FLING_MS, timeout=15, check=False)
        return
    swipe = f'input swipe {LIST_FLING_X} {y1} {LIST_FLING_X} {y2} {LIST_FLING_MS}'
    gap = f'sleep {LIST_FLING_GAP_S}'
    await adb('shell', f'; {gap}; '.join([swipe] * count),
              timeout=max(20, count + 10), check=False)


async def tap_settings_tab(rows):
    """Re-select Settings. Caller already dumped; do not fling."""
    found = locate_text(rows, 'Settings')
    if not found:
        raise RuntimeError('Settings tab not visible while restoring residency')
    row, x, y = found
    event('settings_tab_retap', node=row, reason='list_not_open')
    await adb('shell', 'input', 'tap', x, y)
    await asyncio.sleep(0.5)


async def focus_settings_list(rows):
    """Give PAGE_DOWN a Settings-list target, not chips, SeekBars, or tabs.

    Job 16610532958: Petrol / drivetrain chips start at x=33 and consume
    KEYCODE_PAGE_DOWN. LIST_FOCUS_X stays left of those chips and of
    SeekBar thumbs (x>=99). Never tap the catalog CTA.
    """
    candidates = []
    for needle in ('CONNECTION', 'Gauge style', 'Vehicle profile',
                   'DIAGNOSTIC', 'Recommended adapter', 'FUEL AND DRIVETRAIN'):
        found = locate_text(rows, needle)
        if not found:
            continue
        row, _x, y = found
        candidates.append((needle, row, LIST_FOCUS_X, y))
    for y in (LIST_FOCUS_Y, 120, 80, 300, 400, 160):
        candidates.append(('', None, LIST_FOCUS_X, y))
    for text, row, x, y in candidates:
        if y >= 650:
            continue
        if point_hits_interactive(x, y, rows):
            continue
        event('settings_list_focus', text=text, node=row, x=x, y=y)
        await adb('shell', 'input', 'tap', x, y)
        await asyncio.sleep(0.12)
        return


async def gutter_nudge(upward=False):
    """One short left-gutter swipe when PAGE_DOWN is a no-op.

    Not a burst: job 16610280973's eight flings left Settings. x stays
    left of chips and the Dashboard tab's tap target (y>=684).
    """
    y1, y2 = (GUTTER_NUDGE_Y2, GUTTER_NUDGE_Y1) if upward else (
        GUTTER_NUDGE_Y1, GUTTER_NUDGE_Y2)
    event('recipes_gutter_nudge', x=LIST_FOCUS_X, y1=y1, y2=y2,
          ms=GUTTER_NUDGE_MS, upward=upward)
    await adb('shell', 'input', 'swipe', LIST_FOCUS_X, y1, LIST_FOCUS_X, y2,
              GUTTER_NUDGE_MS, timeout=15, check=False)


async def page_settings_list(upward=False):
    """One page on the focused Settings list. Never swipe or fling.

    Job 16610280973: eight gutter flings overshot Service Recipes to Gauge
    style. PAGE_DOWN/UP stay on the focused scrollable; the caller dumps
    and checks settings_list_open after each step.
    """
    key = 'KEYCODE_PAGE_UP' if upward else 'KEYCODE_PAGE_DOWN'
    event('recipes_page_scroll', key=key, upward=upward)
    await adb('shell', 'input', 'keyevent', key, timeout=8, check=False)


async def find_text(text, exact=False, scroll=True):
    """Dump until text or content-desc matches. Scroll only for list rows.

    Bottom-nav Settings is never below the fold. If it is missing we are
    still on Connect (or the session already dropped). Swiping that screen
    cannot create the tab — job 16609394827 proved the three chore swipes
    only scrolled the disconnect picker.

    Service Recipes sits below CONNECTION, the huge VEHICLE PROFILE, FUEL
    AND DRIVETRAIN, and DIAGNOSTICS. Jobs 16610280973 / 16610702070: PAGE_DOWN
    and gutter nudge never reached the tile before ELM drop / job timeout.
    Device DEX uiautomator.jar cannot feed javac — compile against host
    android.jar plus Java stubs, then scrollIntoView once residency holds.
    Do not PAGE_DOWN or fling the Settings list for this query. Mode 01
    keepalive keeps the session through the dumps. Locate dumps skip
    prepare_window (job 16609695855).
    """
    if not isinstance(text, str) or not 0 < len(text) <= 100:
        raise ValueError('Invalid UI text')
    recipes = scroll and is_recipes_query(text)
    recovered = 0
    scroll_done = False
    for attempt in range(TAP_SCROLL_ATTEMPTS + 1):
        rows = await dump('locate', screenshot=False, prepare=False)
        if recipes:
            labels = recipe_test_labels(rows)
            event('recipe_test_labels', attempt=attempt, labels=labels,
                  settings_list=settings_list_open(rows),
                  dashboard_surface=dashboard_surface(rows))
            found = locate_recipes(rows)
        else:
            found = locate_text(rows, text, exact)
        if found:
            return found, attempt
        if attempt >= TAP_SCROLL_ATTEMPTS:
            break
        if not scroll:
            event('wait_until_text', text=text, attempt=attempt + 1)
            await asyncio.sleep(0.8)
            continue
        if recipes and session_dropped(rows):
            if recovered >= RECIPES_RECOVERIES:
                raise RuntimeError(
                    f'UI text not visible: {text!r} (session dropped during Settings scroll)'
                )
            recovered += 1
            scroll_done = False
            event('recipes_session_dropped', attempt=attempt, recovery=recovered)
            await enter_dashboard()
            found_tab, _ = await find_text('Settings', scroll=False)
            row, x, y = found_tab
            event('selected_observed_ui_node', text='Settings', node=row,
                  node_label=node_primary_label(row),
                  scroll_attempts=0, scrolled=False)
            await adb('shell', 'input', 'tap', x, y)
            await asyncio.sleep(0.5)
            continue
        if recipes and dashboard_surface(rows):
            event('settings_residency_lost', attempt=attempt,
                  dashboard=True)
            scroll_done = False
            await tap_settings_tab(rows)
            continue
        if recipes and locate_text(rows, 'Settings') is None and not settings_list_open(rows):
            event('settings_residency_lost', attempt=attempt,
                  dashboard=False)
            scroll_done = False
            await tap_settings_tab(rows)
            continue
        if recipes:
            # Job 16612438750: 11 scrollIntoView looks, settings_list true,
            # labels still []. Job 16612287354 d05 PAGE_DOWN later revealed
            # the tile at [16,199][464,303]. Page the list every look.
            event('recipes_direct_nav', text=text, attempt=attempt,
                  method='page_down+scroll_into_view')
            await fling_list(FLINGS_PER_LOOK, upward=False)
            await scroll_into_view('Service Recipes')
            await asyncio.sleep(0.3)
            continue
        event('scroll_until_text', text=text, attempt=attempt + 1,
              upward=False)
        await fling_list(FLINGS_PER_LOOK, upward=False)
        await asyncio.sleep(0.15)
    raise RuntimeError(f'UI text not visible: {text!r}')


async def enter_dashboard():
    """Form Connect finishes 14/14 on the last-adapter card (Connect now).

    Job 16609550520 waited for Settings there and timed out. Tap Connect now
    if present; never swipe. Ready signal is Settings\\nTab 5 of 5 or
    Dashboard\\nTab 1 of 5.
    """
    for attempt in range(TAP_SCROLL_ATTEMPTS + 1):
        rows = await dump('locate', screenshot=False)
        if dashboard_ready(rows):
            event('dashboard_tabs_ready', attempt=attempt)
            return
        now = locate_text(rows, 'Connect now')
        if now:
            row, x, y = now
            event('selected_observed_ui_node', text='Connect now', node=row,
                  node_label=node_primary_label(row),
                  scroll_attempts=attempt, scrolled=False)
            await adb('shell', 'input', 'tap', x, y)
            await asyncio.sleep(0.8)
            continue
        if attempt >= TAP_SCROLL_ATTEMPTS:
            break
        event('wait_until_dashboard', attempt=attempt + 1)
        await asyncio.sleep(0.8)
    raise RuntimeError('Dashboard Settings tab not visible after Connect')


async def tap_text(text, exact=False, scroll=True):
    if text == 'Connect now':
        rows = await dump('locate', screenshot=False)
        if dashboard_ready(rows):
            event('connect_now_skipped', reason='dashboard_tabs_ready')
            return
        found = locate_text(rows, text, exact)
        if found:
            row, x, y = found
            label = node_primary_label(row)
            if not label:
                raise RuntimeError('Refusing to tap a node with empty text and content-desc')
            event('selected_observed_ui_node', text=text, node=row,
                  node_label=label, scroll_attempts=0, scrolled=False)
            await adb('shell', 'input', 'tap', x, y)
            return
        found, attempt = await find_text(text, exact, scroll=False)
    else:
        found, attempt = await find_text(text, exact, scroll)
    row, x, y = found
    label = node_primary_label(row)
    if not label:
        raise RuntimeError('Refusing to tap a node with empty text and content-desc')
    event('selected_observed_ui_node', text=text, node=row, node_label=label,
          scroll_attempts=attempt, scrolled=bool(scroll) and text != 'Connect now')
    await adb('shell', 'input', 'tap', x, y)
    if text == 'Settings':
        # Job 16612166781: 0.5s then uiautomator dump returned 58 bytes
        # (no hierarchy) and the ELM TCP session dropped. Wait for the
        # Settings list to paint before the recipes hunt dumps.
        await asyncio.sleep(3)


class ObservedWriter:
    def __init__(self, writer, connection):
        self.writer, self.connection = writer, connection
    def write(self, data):
        event('tcp_write_attempt', connection=self.connection, payload_hex=data.hex(),
              payload_ascii=data.decode('ascii', errors='backslashreplace'))
        return self.writer.write(data)
    async def drain(self):
        await self.writer.drain()
        event('tcp_write_drained', connection=self.connection)
    def __getattr__(self, key):
        return getattr(self.writer, key)


class DeviceRig(ReplayServer):
    def __init__(self):
        super().__init__('tool/obd_test_rig/mode08_replay_fixtures.json',
                         default_scenario='normal_headered_multi_block')
        self.target = None
        self.held = None
        self.release = None
        self.clients = {}
        self.states = {}
        self.connection_counter = 0
    def log_event(self, kind, details):
        event('reference_' + kind, **details)
    async def handle_client(self, reader, writer):
        self.connection_counter += 1
        connection = self.connection_counter
        proxy = ObservedWriter(writer, connection)
        self.clients[connection] = proxy
        try:
            await super().handle_client(reader, proxy)
        finally:
            self.clients.pop(connection, None)
            self.states.pop(connection, None)
    async def process_command(self, raw_cmd, state, writer):
        compact = raw_cmd.replace(' ', '').upper()
        self.states[writer.connection] = state
        event('tcp_request_received', connection=writer.connection, command=compact,
              headers=state.headers)
        if self.target == compact:
            self.target = None
            event('mode08_response_held', connection=writer.connection, command=compact)
            self.held.set_result(dict(connection=writer.connection, command=compact))
            try:
                await asyncio.wait_for(self.release.wait(), timeout=15)
                event('mode08_hold_released', connection=writer.connection, command=compact)
            except asyncio.TimeoutError:
                event('mode08_hold_deadline', connection=writer.connection, command=compact)
                writer.close()
                return True
        keepalive = mode01_keepalive_line(compact, headers=state.headers, spaces=state.spaces)
        if keepalive is not None:
            event('tcp_keepalive_reply', connection=writer.connection, command=compact)
            await ReplayServer._send_reply(self, writer, state, keepalive, echo=raw_cmd)
            return False
        return await super().process_command(raw_cmd, state, writer)
    def arm(self, command):
        if self.target is not None or (self.release and not self.release.is_set()):
            raise RuntimeError('An earlier hold is still active')
        for state in self.states.values():
            state.step_index = 0
        self.target = command
        self.held = asyncio.get_running_loop().create_future()
        self.release = asyncio.Event()
        event('host_rig_armed', command=command)


async def actual_os_snapshot(label):
    for service in ('activity', 'power'):
        data = await adb('shell','dumpsys',service, timeout=20, check=False)
        path = OUT / (unique_name(label + '_' + service) + '.txt')
        path.write_bytes(data)
        event('native_state_captured', service=service, file=path.name,
              sha256=hashlib.sha256(data).hexdigest())
    data = await adb('shell','date','+%s',timeout=10,check=False)
    uptime = await adb('shell','cat','/proc/uptime',timeout=10,check=False)
    event('device_clock_observation', epoch_seconds=data.decode(errors='replace').strip(),
          uptime=uptime.decode(errors='replace').strip())


async def case(rig, index, click_text):
    global ACTIVE_RUN
    if index not in (1,2,3):
        raise ValueError('Only the three agreed D05 cases are allowed')
    ACTIVE_RUN = f'd05_{index}_{time.time_ns()}'
    command = '0820' if index == 2 else '0800'
    action = 'SLEEP' if index == 2 else 'HOME'
    await dump('before_discovery')
    rig.arm(command)
    click = asyncio.create_task(tap_text(click_text))
    try:
        receipt = await asyncio.wait_for(asyncio.shield(rig.held), timeout=50)
        event('held_query_confirmed_before_os_command', receipt=receipt, action=action)
        await adb('shell','input','keyevent','223' if index == 2 else '3', timeout=8)
        # Pacing only; actual Android state/logcat are the evidence.
        await asyncio.sleep(0.2)
        if index == 2:
            await wake_and_unlock()
        await launch_app()
        rig.release.set()
        await click
        await asyncio.sleep(2)
        await actual_os_snapshot('after_resume')
        await dump('mode08_terminal')
        event('case_observations_complete', index=index, acceptance='PENDING_INDEPENDENT_REVIEW')
    finally:
        rig.target = None
        rig.release.set()
        if not click.done():
            click.cancel()
        await asyncio.gather(click, return_exceptions=True)
        ACTIVE_RUN = None


def read_control():
    request = urllib.request.Request(CONTROL_URL, headers={'JOB-TOKEN': os.environ['CI_JOB_TOKEN']})
    with urllib.request.urlopen(request, timeout=10) as reply:
        data = reply.read(65537)
    if len(data) > 65536:
        raise ValueError('Control document exceeds 64 KiB')
    parsed = json.loads(data)
    if set(parsed) != {'version','commands'} or parsed['version'] != 1 or not isinstance(parsed['commands'], list):
        raise ValueError('Invalid control document')
    return parsed['commands'], hashlib.sha256(data).hexdigest()


async def main():
    if os.environ.get('CI_PROJECT_ID') != '86385809':
        raise RuntimeError('Wrong project')
    if hashlib.sha256(Path('candidate.apk').read_bytes()).hexdigest() != CANDIDATE:
        raise RuntimeError('Wrong fixed APK')
    if (await adb('get-state')).decode().strip() != 'device':
        raise RuntimeError('Disposable emulator not ready')
    await ensure_scroll_jar()
    rig = DeviceRig()
    listener = await asyncio.start_server(rig.handle_client, '127.0.0.1', 35008)
    await adb('reverse','tcp:35008','tcp:35008')
    native_log = (OUT/'android_logcat.txt').open('wb')
    logcat = subprocess.Popen(['adb','-s',SERIAL,'logcat','-v','epoch'],stdout=native_log,stderr=subprocess.STDOUT)
    event('device_controller_started', candidate_sha256=CANDIDATE, evidence_level='installed_apk_android',
          fixture_sha256=rig.file_hash, serial=SERIAL)
    seen = set()
    failed = []
    cases = []
    deadline = time.monotonic()+900
    idle_deadline = time.monotonic()+600
    finished = False
    try:
        await launch_app()
        await dump('initial')
        print('ANDROID_CONTROLLER_READY',flush=True)
        while time.monotonic() < deadline and time.monotonic() < idle_deadline:
            try:
                commands, digest = await asyncio.to_thread(read_control)
            except (OSError, ValueError) as exc:
                event('control_read_error', error_type=type(exc).__name__)
                await asyncio.sleep(5)
                continue
            for item in commands:
                if not isinstance(item,dict) or not isinstance(item.get('id'),int) or not 1 <= item['id'] <= 200:
                    raise ValueError('Bad control operation ID')
                if item['id'] in seen:
                    continue
                seen.add(item['id'])
                idle_deadline = time.monotonic()+600
                event('approved_ui_operation', control_sha256=digest, operation=item)
                try:
                    op = item.get('op')
                    if op == 'dump':
                        await dump('manual_view')
                    elif op == 'tap_text':
                        scroll = item.get('scroll', True)
                        await tap_text(item['text'], bool(item.get('exact', False)),
                                       scroll=scroll is not False)
                    elif op == 'tap':
                        x,y = int(item['x']),int(item['y'])
                        if not (0<=x<480 and 0<=y<800): raise ValueError('Coordinate bounds')
                        await adb('shell','input','tap',x,y)
                    elif op == 'swipe':
                        v = [int(item[k]) for k in ('x1','y1','x2','y2')]
                        if not all(0<=v[i]<(480 if i%2==0 else 800) for i in range(4)): raise ValueError('Coordinate bounds')
                        await adb('shell','input','swipe',*v,400)
                    elif op == 'key':
                        keys={'BACK':4,'HOME':3,'WAKEUP':224,'SLEEP':223,'ENTER':66}
                        await adb('shell','input','keyevent',keys[item['key']])
                    elif op == 'replace_numeric':
                        text=item['text']
                        if text not in ('127.0.0.1','35008'): raise ValueError('Only loopback endpoint input permitted')
                        await adb('shell','input','keyevent','123',*(['67']*24))
                        await adb('shell','input','text',text)
                    elif op == 'launch':
                        await launch_app()
                    elif op == 'd05':
                        if item['index'] in cases: raise ValueError('Run index already completed')
                        await case(rig,item['index'],item.get('button_text','Discover Mode 08'))
                        cases.append(item['index'])
                    elif op == 'finish':
                        finished=True
                        break
                    else:
                        raise ValueError('Unsupported UI operation')
                    if op not in ('dump','d05','finish'):
                        if op == 'tap_text' and item.get('text') == 'Connect':
                            await enter_dashboard()
                        elif op == 'tap_text' and item.get('text') in (
                                'Settings', 'Service Recipes'):
                            # Locate already dumped the tab / recipes tile.
                            # Another 10s after_action dump lets Mode 01 NO
                            # DATA drop ELM before Discover Mode 08 runs.
                            pass
                        else:
                            await asyncio.sleep(1)
                            await dump('after_action')
                except Exception as exc:
                    failed.append(dict(id=item['id'],error=type(exc).__name__+': '+str(exc)))
                    event('operation_failed', operation_id=item['id'], error=failed[-1]['error'])
            if finished: break
            await asyncio.sleep(5)
    finally:
        if rig.release: rig.release.set()
        listener.close()
        await listener.wait_closed()
        for writer in list(rig.clients.values()): writer.close()
        await adb('reverse','--remove','tcp:35008',check=False)
        if logcat.poll() is None:
            logcat.terminate()
            try: logcat.wait(timeout=5)
            except subprocess.TimeoutExpired:
                logcat.kill(); logcat.wait(timeout=5)
        native_log.close()
        result={'evidence_level':'installed_apk_android_observations','candidate_sha256':CANDIDATE,
                'completed_case_indices':cases,'ui_operation_failures':failed,
                'all_three_observed':sorted(cases)==[1,2,3], 'review_disposition':'PENDING_INDEPENDENT_REVIEW',
                'owned_logcat_stopped':logcat.poll() is not None,'finished_by_operator':finished}
        (OUT/'execution_result.json').write_text(json.dumps(result,indent=2)+'\n')
        print('ANDROID_EXECUTION_RESULT '+json.dumps(result),flush=True)
    return 0 if sorted(cases)==[1,2,3] else 1


if __name__=='__main__':
    raise SystemExit(asyncio.run(main()))

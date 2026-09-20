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
TAP_SCROLL_ATTEMPTS = 8
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
# Job 16609802535: 6 gutter flings reached DIAGNOSTIC TRANSCRIPT (UI 914).
# Burst the remaining Adapter / FieldEvent / Export / Manual panels only
# after CONNECTION (or the Settings title) is on screen.
RECIPES_BURST_FLINGS = 8
RECIPES_NEEDLES = (
    'Service Recipes',
    'Active Tests',
    'Service-Rezepte',
    '車行診斷配方',
)
RECIPES_RECOVERIES = 2
DRAWN_WAIT_SECONDS = 180
DRAWN_POLL_SLEEP = 2
REMOTE_DUMP = '/sdcard/d05_window.xml'
SCROLL_JAR_REMOTE = '/data/local/tmp/d05_scroll.jar'
SCROLL_JAVA = Path(__file__).resolve().parent / 'd05_scroll.java'
SCROLL_NEEDLE_OK = re.compile(r'^[A-Za-z0-9 &._-]{1,80}$')
SCROLL_JAR_READY = False
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
            if 'recipe' in low or 'test' in low:
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


def settings_list_open(rows):
    """Settings *list*, not merely the Settings\\nTab 5 of 5 destination.

    Job 16609955129 dumped Dashboard gauges after the burst while that tab
    was still in the tree. CONNECTION / the non-tab Settings title are the
    residency signal.
    """
    for row in rows:
        for value in node_labels(row):
            first = value.split('\n', 1)[0].strip()
            low = first.lower()
            if low == 'settings' and 'tab' not in value.lower():
                return True
            if low in ('connection', 'disconnect'):
                return True
            if any(token in low for token in (
                'vehicle profile', 'fuel and drivetrain', 'diagnostic transcript',
                'service recipes', 'experimental', 'appearance',
                'what the adapter says', 'manual command',
            )):
                return True
    return False


def dashboard_surface(rows):
    """Gauge grid / 'No data — Unverified' without the Settings list."""
    if settings_list_open(rows) or session_dropped(rows):
        return False
    for line in first_line_values(rows):
        low = line.lower()
        if 'no data' in low or 'unverified' in low:
            return True
    return (locate_text(rows, 'Dashboard') is not None and
            locate_text(rows, 'Settings') is not None)


def still_above_recipes(rows):
    tokens = (
        'vehicle profile', 'fuel and drivetrain', 'diagnostic transcript',
        'what the adapter says', 'manual command',
    )
    return any(any(token in line.lower() for token in tokens)
               for line in first_line_values(rows))


def past_recipes(rows):
    """Overshot the tile into Experimental / Language / Appearance."""
    if locate_text(rows, 'Settings') is None:
        return False
    tokens = ('experimental', 'appearance', 'open-source', 'recommended', 'language /')
    return any(any(token in line.lower() for token in tokens)
               for line in first_line_values(rows))


def locate_recipes(rows):
    """Tile title, localized variants, or a first line that names the row."""
    for needle in RECIPES_NEEDLES:
        found = locate_text(rows, needle)
        if found:
            return found
    matching = []
    for row in rows:
        if row.get('enabled') != 'true':
            continue
        labels = node_labels(row)
        first = ' '.join(value.split('\n', 1)[0].lower() for value in labels)
        if not ('recipe' in first or 'active test' in first or 'service-rezepte' in first):
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


def _android_jar():
    home = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT') or ''
    platforms = Path(home) / 'platforms'
    preferred = platforms / 'android-29' / 'android.jar'
    if preferred.is_file():
        return preferred
    jars = sorted(platforms.glob('android-*/android.jar')) if platforms.is_dir() else []
    return jars[-1] if jars else None


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
    home = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT') or ''
    build_tools = Path(home) / 'build-tools'
    if build_tools.is_dir():
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


async def ensure_scroll_jar():
    """Build and push the one-shot UiAutomator scrollIntoView helper."""
    global SCROLL_JAR_READY
    if SCROLL_JAR_READY:
        return
    try:
        work = OUT / 'scroll-build'
        work.mkdir(parents=True, exist_ok=True)
        uia = work / 'uiautomator.jar'
        await adb('pull', '/system/framework/uiautomator.jar', str(uia),
                  timeout=20, check=False)
        android_jar = _android_jar()
        javac = _javac()
        dexer = _dexer()
        if not (SCROLL_JAVA.is_file() and javac and android_jar and dexer
                and uia.is_file() and uia.stat().st_size > 0):
            event('scroll_jar_compile_skipped', javac=bool(javac),
                  android_jar=str(android_jar) if android_jar else '',
                  uiautomator_bytes=uia.stat().st_size if uia.is_file() else 0,
                  dexer=dexer[0] if dexer else '')
            SCROLL_JAR_READY = True
            return
        source = work / 'D05Scroll.java'
        source.write_text(SCROLL_JAVA.read_text(encoding='utf-8'))
        javac_cmds = (
            [javac, '--release', '8', '-cp', str(android_jar) + ':' + str(uia),
             '-d', str(work), str(source)],
            [javac, '-source', '8', '-target', '8', '-bootclasspath', str(android_jar),
             '-cp', str(uia), '-d', str(work), str(source)],
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
            event('scroll_jar_javac_failed',
                  stderr=(compiled.stderr.decode(errors='replace')[:1500] if compiled else ''))
            SCROLL_JAR_READY = True
            return
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
            event('scroll_jar_dex_failed',
                  stderr=dexed.stderr.decode(errors='replace')[:1500])
            SCROLL_JAR_READY = True
            return
        await adb('push', str(jar_out), SCROLL_JAR_REMOTE, timeout=20, check=False)
        event('scroll_jar_ready', remote=SCROLL_JAR_REMOTE,
              sha256=hashlib.sha256(jar_out.read_bytes()).hexdigest())
    except Exception as exc:
        event('scroll_jar_compile_failed', error=type(exc).__name__ + ': ' + str(exc))
    SCROLL_JAR_READY = True


async def scroll_into_view(needle):
    """UiAutomator scrollIntoView for a Flutter content-desc prefix.

    Job 16610137504 selected Service Recipes this way. Gutter flings plus
    locate dumps are the fallback when the jar cannot be built.
    """
    if not isinstance(needle, str) or not SCROLL_NEEDLE_OK.fullmatch(needle):
        raise ValueError('Invalid scroll needle')
    event('uiautomator_scroll_into_view', needle=needle)
    await ensure_scroll_jar()
    await adb('shell', 'uiautomator', 'runtest', SCROLL_JAR_REMOTE, '-c', 'D05Scroll',
              '-e', 'needle', needle, timeout=60, check=False)


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


async def find_text(text, exact=False, scroll=True):
    """Dump until text or content-desc matches. Scroll only for list rows.

    Bottom-nav Settings is never below the fold. If it is missing we are
    still on Connect (or the session already dropped). Swiping that screen
    cannot create the tab — job 16609394827 proved the three chore swipes
    only scrolled the disconnect picker.

    Service Recipes sits below CONNECTION, the huge VEHICLE PROFILE, FUEL
    AND DRIVETRAIN, and DIAGNOSTICS. Job 16609955129 burst before the list
    was confirmed and landed on Dashboard gauges — dump first, re-tap
    Settings if gauges show. Job 16610137504 reached the tile with
    UiAutomator scrollIntoView, then reference_disconnect yanked Connect;
    prefer that scroll once residency holds, keep Mode 01 alive, and
    reconnect+reenter before failing op8. Locate dumps skip prepare_window
    (job 16609695855).
    """
    if not isinstance(text, str) or not 0 < len(text) <= 100:
        raise ValueError('Invalid UI text')
    recipes = scroll and is_recipes_query(text)
    recovered = 0
    scroll_done = False
    burst_done = False
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
            burst_done = False
            event('recipes_session_dropped', attempt=attempt, recovery=recovered)
            await enter_dashboard()
            found_tab, _ = await find_text('Settings', scroll=False)
            row, x, y = found_tab
            event('selected_observed_ui_node', text='Settings', node=row,
                  scroll_attempts=0, scrolled=False)
            await adb('shell', 'input', 'tap', x, y)
            await asyncio.sleep(0.5)
            continue
        if recipes and (dashboard_surface(rows) or not settings_list_open(rows)):
            event('settings_residency_lost', attempt=attempt,
                  dashboard=dashboard_surface(rows))
            scroll_done = False
            burst_done = False
            await tap_settings_tab(rows)
            continue
        if recipes and not scroll_done:
            event('recipes_direct_nav', text=text, attempt=attempt,
                  method='uiautomator_scroll_into_view')
            await scroll_into_view('Service Recipes')
            scroll_done = True
            await asyncio.sleep(0.2)
            continue
        upward = bool(recipes and past_recipes(rows) and not still_above_recipes(rows))
        if recipes and not upward and not burst_done:
            event('recipes_burst_fling', count=RECIPES_BURST_FLINGS,
                  attempt=attempt + 1)
            await fling_list(RECIPES_BURST_FLINGS)
            burst_done = True
        else:
            event('scroll_until_text', text=text, attempt=attempt + 1,
                  upward=upward)
            await fling_list(FLINGS_PER_LOOK, upward=upward)
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
            event('selected_observed_ui_node', text=text, node=row,
                  scroll_attempts=0, scrolled=False)
            await adb('shell', 'input', 'tap', x, y)
            return
        found, attempt = await find_text(text, exact, scroll=False)
    else:
        found, attempt = await find_text(text, exact, scroll)
    row, x, y = found
    event('selected_observed_ui_node', text=text, node=row,
          scroll_attempts=attempt, scrolled=bool(scroll) and text != 'Connect now')
    await adb('shell', 'input', 'tap', x, y)
    if text == 'Settings':
        # Let go_router paint CONNECTION before op8 bursts (job 16609955129).
        await asyncio.sleep(0.5)


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

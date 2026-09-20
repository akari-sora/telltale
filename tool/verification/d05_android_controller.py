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
import subprocess
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

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
DRAWN_WAIT_SECONDS = 180
DRAWN_POLL_SLEEP = 2
REMOTE_DUMP = '/sdcard/d05_window.xml'
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


async def dump(label='view', screenshot=True):
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


async def tap_text(text, exact=False):
    if not isinstance(text, str) or not 0 < len(text) <= 100:
        raise ValueError('Invalid UI text')
    rows = await dump('locate', screenshot=False)
    matching = []
    for row in rows:
        values = [row['text'] or '', row['desc'] or '']
        if row['enabled'] != 'true':
            continue
        if any(value == text if exact else text.lower() in value.lower() for value in values):
            try:
                x1,y1,x2,y2 = bounds(row)
                matching.append(((x2-x1)*(y2-y1), row, (x1+x2)//2, (y1+y2)//2))
            except ValueError:
                continue
    if not matching:
        raise RuntimeError(f'UI text not visible: {text!r}')
    _, row, x, y = min(matching, key=lambda x:x[0])
    event('selected_observed_ui_node', text=text, node=row)
    await adb('shell','input','tap',x,y)


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
                        await tap_text(item['text'], bool(item.get('exact',False)))
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
                            await asyncio.sleep(25)
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

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
OUT.mkdir(exist_ok=True)
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


def event(kind: str, **values):
    global SEQ
    SEQ += 1
    data = dict(seq=SEQ, host_epoch_ns=time.time_ns(), host_monotonic_ns=time.monotonic_ns(),
                event=kind, run_id=ACTIVE_RUN, **values)
    with EVENT_FILE.open('a') as stream:
        stream.write(json.dumps(data, ensure_ascii=False) + '\n')
    print(json.dumps(data, ensure_ascii=False), flush=True)
    return data


async def adb(*args, timeout=40, check=True):
    command = ['adb', '-s', SERIAL, *[str(a) for a in args]]
    started = event('adb_start', argv=command)
    def run():
        return subprocess.run(command, capture_output=True, timeout=timeout)
    result = await asyncio.to_thread(run)
    event('adb_exit', start_seq=started['seq'], returncode=result.returncode,
          stdout=result.stdout.decode(errors='replace')[:2000] if args[0] != 'exec-out' else '<binary-or-raw>',
          stderr=result.stderr.decode(errors='replace')[:1000])
    if check and result.returncode:
        raise RuntimeError('ADB command failed: ' + ' '.join(map(str, args)))
    return result.stdout


def unique_name(label):
    if not re.fullmatch(r'[a-zA-Z0-9_-]{1,60}', label):
        raise ValueError('Invalid evidence label')
    return f'{SEQ:05d}_{label}'


async def dump(label='view', screenshot=True):
    name = unique_name(label)
    await adb('shell', 'uiautomator', 'dump', '--compressed', '/sdcard/d05_window.xml', timeout=45)
    xml = await adb('exec-out', 'cat', '/sdcard/d05_window.xml')
    (OUT / (name + '.xml')).write_bytes(xml)
    start = xml.find(b'<?xml')
    if start < 0:
        start = xml.find(b'<hierarchy')
    root = ET.fromstring(xml[start:])
    rows = [dict(text=n.get('text'), desc=n.get('content-desc'), bounds=n.get('bounds'),
                 enabled=n.get('enabled'), clickable=n.get('clickable'), clazz=n.get('class'))
            for n in root.iter('node') if n.get('text') or n.get('content-desc') or n.get('class') == 'android.widget.EditText']
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
            await adb('shell','input','keyevent','224',timeout=8)
            await adb('shell','wm','dismiss-keyguard',timeout=8,check=False)
        await adb('shell','am','start','-n',PACKAGE+'/.MainActivity',timeout=10)
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
        await adb('shell','am','start','-n',PACKAGE+'/.MainActivity',timeout=60)
        await asyncio.sleep(8)
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
                        await adb('shell','input','keyevent','224')
                        await adb('shell','wm','dismiss-keyguard',check=False)
                        await adb('shell','am','start','-n',PACKAGE+'/.MainActivity')
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

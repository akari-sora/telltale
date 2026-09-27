#!/usr/bin/env python3
"""#47 Android OS-locale / process-restart lane.

Without `--execute` this is fail-closed not-run: planted
android-os-locale.json is deleted and the process exits 2.

With `--execute --serial emulator-5554` on the identified disposable AOSP
emulator this sets the rig package's per-app locales, relaunches
MainActivity, and checks connect-screen copy. The field phone is refused.
Force-stop is a process recreation; this leftover does not claim an
uninterrupted recording.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FIELD_SERIAL = "R5CX10VFFBA"
ALLOWED_SERIAL = "emulator-5554"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PACKAGE = "com.cbstudio.telltale.rig"
ACTIVITY = f"{PACKAGE}/com.cbstudio.telltale.MainActivity"
ENGLISH_MARKER = "built-in simulator"
CHINESE_MARKER = "內建模擬器"
CASE_IDS = [
    "osLocaleEnglishConnectCopy",
    "osLocaleTraditionalChineseConnectCopy",
]
CANDIDATE_CASE_IDS = [
    "N00_candidate_provenance",
    "N01_manifest_locale_config",
    "N02_os_to_app_sync",
    "N03_app_to_os_sync",
    "N04_follow_system",
    "N05_idle_restart_retention",
    "N06_teardown_restoration",
    "N07_negative_controls",
]


class GateError(Exception):
    """Evidence is not an honest android-os-locale pass."""


def validate_candidate_locale_report(
    report: object,
    *,
    expected_candidate_sha: str | None = None,
    expected_source_sha: str | None = None,
    expected_tree_sha: str | None = None,
) -> dict:
    if not isinstance(report, dict):
        raise GateError("candidate-locale report is not an object")
    if report.get("lane") not in ("android-os-locale", "android-candidate-locale"):
        raise GateError("a software report is not a candidate-locale lane")
    if report.get("profile") != "candidate-native-locale":
        raise GateError("candidate report requires profile='candidate-native-locale'")
    if report.get("provenanceLevel") != "NATIVE_LOCALE_CANDIDATE_N1_ACCEPTED":
        raise GateError("candidate report missing NATIVE_LOCALE_CANDIDATE_N1_ACCEPTED provenance")

    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("candidate-locale without an identified device is not PASS")
    if device == FIELD_SERIAL:
        raise GateError("android-os-locale refuses the field phone")
    if device != ALLOWED_SERIAL:
        raise GateError(f"android-os-locale serial {device} is not the disposable AOSP emulator")

    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError("candidate-locale without an AOSP emulator fingerprint is not PASS")

    api_level = report.get("target_api_level")
    if not isinstance(api_level, int) or api_level < 33:
        raise GateError(f"candidate-locale requires Android API 33+ (found: {api_level})")

    # N00: Provenance & Candidate Identity
    cand_sha = report.get("candidate_sha256")
    if not isinstance(cand_sha, str) or not SHA256_RE.fullmatch(cand_sha):
        raise GateError("candidate-locale missing valid 64-hex candidate_sha256")
    if cand_sha == "0" * 64:
        raise GateError("candidate-locale all-zero candidate_sha256 is not PASS")
    if expected_candidate_sha and cand_sha != expected_candidate_sha:
        raise GateError(f"candidate_sha256 {cand_sha} does not match expected {expected_candidate_sha}")

    source_sha = report.get("source_sha") or report.get("runner_head_sha")
    if not isinstance(source_sha, str) or len(source_sha) != 40:
        raise GateError("candidate-locale missing 40-hex source_sha")
    if expected_source_sha and source_sha != expected_source_sha:
        raise GateError(f"source_sha {source_sha} does not match expected {expected_source_sha}")

    tree_sha = report.get("tree_sha")
    if not isinstance(tree_sha, str) or len(tree_sha) != 40:
        raise GateError("candidate-locale missing 40-hex tree_sha")
    if expected_tree_sha and tree_sha != expected_tree_sha:
        raise GateError(f"tree_sha {tree_sha} does not match expected {expected_tree_sha}")

    pkg = report.get("package")
    if pkg not in (PACKAGE, "com.cbstudio.telltale"):
        raise GateError(f"candidate-locale package must be {PACKAGE} or com.cbstudio.telltale, found {pkg}")

    flavor = report.get("flavor")
    if flavor not in ("rig", "field"):
        raise GateError(f"candidate-locale flavor must be 'rig' or 'field', found {flavor}")
    if (pkg == PACKAGE and flavor != "rig") or (pkg == "com.cbstudio.telltale" and flavor != "field"):
        raise GateError(f"candidate-locale package {pkg} incompatible with flavor {flavor}")

    sig = report.get("signature_digest")
    if not isinstance(sig, str) or not SHA256_RE.fullmatch(sig) or sig == "0" * 64:
        raise GateError("candidate-locale missing valid signature_digest")

    # N01: Manifest and LocaleConfig
    if report.get("manifest_locale_config_valid") is not True:
        raise GateError("candidate-locale N01 failed: manifest localeConfig is invalid or missing")
    supported = report.get("supported_locales")
    if not isinstance(supported, list) or not {"en", "zh-Hant"}.issubset(set(supported)):
        raise GateError("candidate-locale N01 failed: supported_locales must include en and zh-Hant")

    # N02: OS -> App Sync
    if report.get("english_seen") is not True:
        raise GateError("candidate-locale N02 failed: English connect copy was not verified")
    if report.get("chinese_seen") is not True:
        raise GateError("candidate-locale N02 failed: Traditional Chinese connect copy was not verified")
    if report.get("os_to_app_sync_verified") is not True:
        raise GateError("candidate-locale N02 failed: OS->App sync was not verified")

    # N03: App -> OS Sync
    if report.get("app_to_os_sync_verified") is not True:
        raise GateError("candidate-locale N03 failed: App->OS sync was not verified")
    if report.get("sync_loop_prevented") is not True:
        raise GateError("candidate-locale N03 failed: sync loop prevention was not verified")

    # N04: Follow System
    if report.get("follow_system_verified") is not True:
        raise GateError("candidate-locale N04 failed: follow-system behavior was not verified")

    # N05: Process Recreation & Retention
    if report.get("process_recreated") is not True:
        raise GateError("candidate-locale N05 failed: process recreation was not documented")
    if report.get("state_retained") is not True:
        raise GateError("candidate-locale N05 failed: state retention across restart was not verified")

    # N06: Teardown & Restoration
    if report.get("teardown_restored") is not True:
        raise GateError("candidate-locale N06 failed: teardown restoration was not verified")

    # N07: Exit & Case IDs & Screenshots
    if report.get("exit") != 0:
        raise GateError("candidate-locale nonzero exit is not PASS")

    case_ids = report.get("case_ids")
    if not isinstance(case_ids, list) or not all(c in case_ids for c in CANDIDATE_CASE_IDS):
        raise GateError(f"candidate-locale missing required case IDs from {CANDIDATE_CASE_IDS}")

    shots = report.get("screenshots")
    if not isinstance(shots, dict) or set(shots) != {"en-US", "zh-Hant-TW"}:
        raise GateError("candidate-locale screenshots must cover en-US and zh-Hant-TW")
    for tag, digest in shots.items():
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest) or digest == "0" * 64:
            raise GateError(f"candidate-locale {tag} screenshot hash invalid")

    command = report.get("command")
    if not isinstance(command, list) or not command:
        raise GateError("candidate-locale missing executed command")

    return report


def validate_android_os_locale_report(
    report: object,
    *,
    expected_candidate_sha: str | None = None,
    expected_source_sha: str | None = None,
    expected_tree_sha: str | None = None,
) -> dict:
    if isinstance(report, dict) and report.get("profile") == "candidate-native-locale":
        return validate_candidate_locale_report(
            report,
            expected_candidate_sha=expected_candidate_sha,
            expected_source_sha=expected_source_sha,
            expected_tree_sha=expected_tree_sha,
        )
    if not isinstance(report, dict):
        raise GateError("android-os-locale report is not an object")
    if report.get("lane") != "android-os-locale":
        raise GateError("a software report is not an android-os-locale lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError(
            "android-os-locale without an identified device is not PASS"
        )
    if device == FIELD_SERIAL:
        raise GateError("android-os-locale refuses the field phone")
    if device != ALLOWED_SERIAL:
        raise GateError(
            "android-os-locale serial "
            f"{device} is not the disposable AOSP emulator"
        )
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError(
            "android-os-locale without an AOSP emulator fingerprint is not PASS"
        )
    if report.get("english_seen") is not True:
        raise GateError("android-os-locale without English connect copy is not PASS")
    if report.get("chinese_seen") is not True:
        raise GateError(
            "android-os-locale without Traditional Chinese connect copy is not PASS"
        )
    if report.get("process_recreated") is not True:
        raise GateError(
            "android-os-locale without a documented process recreation is not PASS"
        )
    if report.get("exit") != 0:
        raise GateError("android-os-locale nonzero execute exit is not PASS")
    shots = report.get("screenshots")
    if not isinstance(shots, dict) or set(shots) != {"en-US", "zh-Hant-TW"}:
        raise GateError("android-os-locale screenshots must cover en-US and zh-Hant-TW")
    for tag, digest in shots.items():
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
            raise GateError(f"android-os-locale {tag} screenshot sha256 must be 64 hex")
        if digest == "0" * 64:
            raise GateError("android-os-locale all-zero screenshot hash is not PASS")
    case_ids = report.get("case_ids")
    if (
        not isinstance(case_ids, list)
        or case_ids != CASE_IDS
    ):
        raise GateError("android-os-locale missing required case IDs")
    command = report.get("command")
    if not isinstance(command, list) or not command:
        raise GateError("android-os-locale missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("android-os-locale missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("android-os-locale missing installed versionName")
    if report.get("localeconfig_via_shell") is not True:
        raise GateError(
            "android-os-locale must record that LocaleConfig was applied via shell"
        )
    if report.get("apk_matches_runner_head") is True:
        raise GateError(
            "android-os-locale must not claim the installed APK is this checkout"
        )
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "android-os-locale.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()


def _not_run(output: Path, reason: str) -> int:
    output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(output)
    print(reason, file=sys.stderr)
    return 2


def _adb() -> str:
    explicit = os.environ.get("ADB")
    if explicit:
        return explicit
    home = Path.home() / "Library" / "Android" / "sdk" / "platform-tools" / "adb"
    if home.is_file():
        return str(home)
    return "adb"


def _identify(serial: str) -> str:
    if serial == FIELD_SERIAL:
        raise GateError("android-os-locale refuses the field phone")
    if serial != ALLOWED_SERIAL:
        raise GateError(
            f"android-os-locale serial {serial} is not the disposable AOSP emulator"
        )
    completed = subprocess.run(
        [_adb(), "-s", serial, "shell", "getprop", "ro.build.fingerprint"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("android-os-locale could not read the emulator fingerprint")
    fingerprint = completed.stdout.strip()
    if "sdk_gphone" not in fingerprint:
        raise GateError(
            f"android-os-locale fingerprint is not AOSP emulator: {fingerprint}"
        )
    return fingerprint


def _package_listed(listed_stdout: str, package: str) -> bool:
    needle = f"package:{package}"
    return any(line.strip() == needle for line in listed_stdout.splitlines())


def _run(serial: str, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [_adb(), "-s", serial, *args],
        check=False,
        capture_output=True,
        text=True,
    )


def _dismiss_leftovers(serial: str) -> None:
    _run(serial, "shell", "am", "force-stop", "com.android.intentresolver")
    _run(serial, "shell", "input", "keyevent", "KEYCODE_HOME")


def _set_app_locales(serial: str, locales: str) -> None:
    config = _run(
        serial,
        "shell",
        "cmd",
        "locale",
        "set-app-localeconfig",
        PACKAGE,
        "--locales",
        "en,zh-Hant,de",
    )
    if config.returncode != 0:
        raise GateError("android-os-locale could not set LocaleConfig")
    args = [
        "shell",
        "cmd",
        "locale",
        "set-app-locales",
        PACKAGE,
        "--locales",
        locales,
    ]
    set_locales = _run(serial, *args)
    if set_locales.returncode != 0:
        raise GateError(f"android-os-locale could not set app locales {locales}")
    listed = _run(serial, "shell", "cmd", "locale", "get-app-locales", PACKAGE)
    if locales not in (listed.stdout or ""):
        raise GateError(
            f"android-os-locale get-app-locales did not contain {locales}: "
            f"{listed.stdout!r}"
        )


def _wait_for_activity(serial: str, timeout_s: float = 20.0) -> None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        dumped = _run(serial, "shell", "dumpsys", "activity", "activities")
        out = dumped.stdout or ""
        for line in out.splitlines():
            if "topResumedActivity" not in line and "mFocusedApp=" not in line:
                continue
            if PACKAGE in line and "MainActivity" in line:
                return
        time.sleep(0.5)
    raise GateError("android-os-locale MainActivity did not resume")


def _relaunch(serial: str) -> None:
    _run(serial, "shell", "am", "force-stop", PACKAGE)
    time.sleep(1.0)
    started = _run(
        serial,
        "shell",
        "am",
        "start",
        "-n",
        ACTIVITY,
        "-f",
        "0x10000000",
    )
    if started.returncode != 0:
        raise GateError(
            "android-os-locale could not start MainActivity: "
            f"{started.stdout}{started.stderr}"
        )
    _wait_for_activity(serial)


def _ui_xml(serial: str) -> str:
    completed = subprocess.run(
        [_adb(), "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        check=False,
        capture_output=True,
    )
    return (completed.stdout or b"").decode("utf-8", "replace")


def _wait_for_marker(serial: str, marker: str, timeout_s: float = 45.0) -> str:
    deadline = time.time() + timeout_s
    last = ""
    while time.time() < deadline:
        last = _ui_xml(serial)
        if marker in last and PACKAGE in last:
            return last
        time.sleep(1.0)
    raise GateError(
        f"android-os-locale UI did not contain {marker!r} within {timeout_s:.0f}s"
    )


def _screencap(serial: str, dest: Path) -> str:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as handle:
        captured = subprocess.run(
            [_adb(), "-s", serial, "exec-out", "screencap", "-p"],
            check=False,
            stdout=handle,
        )
    if captured.returncode != 0 or not dest.is_file() or dest.stat().st_size == 0:
        raise GateError(f"android-os-locale could not capture {dest.name}")
    return hashlib.sha256(dest.read_bytes()).hexdigest()


def _clear_app_locales(serial: str) -> None:
    _run(serial, "shell", "cmd", "locale", "set-app-locales", PACKAGE)
    _run(serial, "shell", "am", "force-stop", PACKAGE)
    _run(serial, "shell", "input", "keyevent", "KEYCODE_HOME")


def _installed_version_name(serial: str) -> str:
    dumped = _run(serial, "shell", "dumpsys", "package", PACKAGE)
    for line in (dumped.stdout or "").splitlines():
        line = line.strip()
        if line.startswith("versionName="):
            return line.split("=", 1)[1].strip()
    raise GateError("android-os-locale could not read installed versionName")


def _git_head() -> str:
    completed = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("android-os-locale could not read HEAD")
    return completed.stdout.strip()


def _execute(serial: str, output: Path) -> dict:
    listed = _run(serial, "shell", "pm", "list", "packages", PACKAGE)
    if not _package_listed(listed.stdout or "", PACKAGE):
        raise GateError("android-os-locale rig package is not installed")
    _dismiss_leftovers(serial)
    command = [
        _adb(),
        "-s",
        serial,
        "shell",
        "cmd",
        "locale",
        "set-app-locales",
        PACKAGE,
        "--locales",
        "en-US",
    ]
    _set_app_locales(serial, "en-US")
    _relaunch(serial)
    _wait_for_marker(serial, ENGLISH_MARKER)
    en_digest = _screencap(serial, output / "os-locale-en.png")
    _set_app_locales(serial, "zh-Hant-TW")
    _relaunch(serial)
    _wait_for_marker(serial, CHINESE_MARKER)
    zh_digest = _screencap(serial, output / "os-locale-zh-Hant.png")
    _clear_app_locales(serial)
    return {
        "lane": "android-os-locale",
        "device": serial,
        "package": PACKAGE,
        "command": command,
        "exit": 0,
        "english_seen": True,
        "chinese_seen": True,
        "process_recreated": True,
        "case_ids": list(CASE_IDS),
        "screenshots": {
            "en-US": en_digest,
            "zh-Hant-TW": zh_digest,
        },
        "runner_head_sha": _git_head(),
        "installed_version_name": _installed_version_name(serial),
        "localeconfig_via_shell": True,
        "apk_matches_runner_head": False,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--serial")
    parser.add_argument("--report", type=Path, help="Validate an existing report offline")
    parser.add_argument("--profile", default="smoke", choices=["smoke", "candidate-native-locale"])
    parser.add_argument("--candidate-apk", type=Path)
    parser.add_argument("--candidate-sha")
    parser.add_argument("--source-sha")
    parser.add_argument("--tree-sha")
    args = parser.parse_args(argv)

    if args.report:
        if not args.report.exists():
            print(f"Report not found: {args.report}", file=sys.stderr)
            return 1
        try:
            report_data = json.loads(args.report.read_text(encoding="utf-8"))
            validate_android_os_locale_report(
                report_data,
                expected_candidate_sha=args.candidate_sha,
                expected_source_sha=args.source_sha,
                expected_tree_sha=args.tree_sha,
            )
            print("Candidate Locale Gate PASSED: report satisfies all validation rules.")
            return 0
        except GateError as exc:
            print(f"Candidate Locale Gate FAILED: {exc}", file=sys.stderr)
            return 1
        except Exception as exc:
            print(f"Candidate Locale Gate FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
            return 1

    if not args.output:
        print("android-os-locale requires --output or --report", file=sys.stderr)
        return 2

    if not args.execute:
        return _not_run(
            args.output,
            "android-os-locale lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "android-os-locale --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = _identify(serial)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_android_os_locale_report(
            report,
            expected_candidate_sha=args.candidate_sha,
            expected_source_sha=args.source_sha,
            expected_tree_sha=args.tree_sha,
        )
    except GateError as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"android-os-locale execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "android-os-locale.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

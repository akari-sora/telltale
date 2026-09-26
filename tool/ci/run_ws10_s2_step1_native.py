#!/usr/bin/env python3
"""WS10-S2 Step 1 Native ISO-TP CTest runner and artifact generator."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

REPO_ROOT = Path(__file__).resolve().parents[2]
NATIVE_DIR = REPO_ROOT / "tool" / "diagnostic_bridge" / "native"

REQUIRED_TESTS = [
    "ws10_isotp_unit_tests",
    "ws10_case_u01",
    "ws10_case_u14",
    "ws10_case_u15",
    "ws10_case_u16",
    "ws10_case_u17",
    "ws10_neg_assertion_fail",
    "ws10_neg_unknown_case",
    "ws10_neg_zero_match",
    "ws10_neg_cli_unknown_case",
    "ws10_neg_cli_unknown_flag",
]


def find_tool(name: str) -> str | None:
    path = shutil.which(name)
    if path:
        return path
    # Check Android NDK cmake path if present
    ndk_root = os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK_ROOT")
    if ndk_root:
        ndk_tool = Path(ndk_root) / "prebuilt" / "linux-x86_64" / "bin" / name
        if ndk_tool.exists() and os.access(ndk_tool, os.X_OK):
            return str(ndk_tool)
    # Check Android SDK cmake installation paths if present
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if android_home:
        for cand in sorted(Path(android_home).glob(f"cmake/*/bin/{name}"), reverse=True):
            if cand.exists() and os.access(cand, os.X_OK):
                return str(cand)
    return None


def run_configuration(cmake_bin: str, ctest_bin: str, build_type: str, output_dir: Path) -> dict:
    with tempfile.TemporaryDirectory(prefix=f"ws10_build_{build_type.lower()}_") as tmp_dir:
        build_dir = Path(tmp_dir)
        config_cmd = [
            cmake_bin,
            "-B", str(build_dir),
            f"-DCMAKE_BUILD_TYPE={build_type}",
            str(NATIVE_DIR),
        ]
        res_config = subprocess.run(config_cmd, capture_output=True, text=True)
        if res_config.returncode != 0:
            raise RuntimeError(f"CMake configuration failed for {build_type}:\nSTDOUT:\n{res_config.stdout}\nSTDERR:\n{res_config.stderr}")

        build_cmd = [cmake_bin, "--build", str(build_dir)]
        res_build = subprocess.run(build_cmd, capture_output=True, text=True)
        if res_build.returncode != 0:
            raise RuntimeError(f"CMake build failed for {build_type}:\nSTDOUT:\n{res_build.stdout}\nSTDERR:\n{res_build.stderr}")

        ctest_cmd = [
            ctest_bin,
            "--test-dir", str(build_dir),
            "--output-on-failure",
            "--no-tests=error",
        ]
        res_ctest = subprocess.run(ctest_cmd, capture_output=True, text=True)
        if res_ctest.returncode != 0:
            raise RuntimeError(f"CTest failed for {build_type}:\nSTDOUT:\n{res_ctest.stdout}\nSTDERR:\n{res_ctest.stderr}")

        # Strict manifest verification: parse executed and passed test names
        test_pattern = re.compile(r"^\s*\d+/\d+\s+Test\s+#\d+:\s+(\S+)\s+\.+\s+Passed", re.MULTILINE)
        passed_tests = test_pattern.findall(res_ctest.stdout)

        missing = set(REQUIRED_TESTS) - set(passed_tests)
        if missing:
            raise RuntimeError(f"CTest missing required tests for {build_type}: {sorted(missing)}")
        extra = set(passed_tests) - set(REQUIRED_TESTS)
        if extra:
            raise RuntimeError(f"CTest executed unapproved extra tests for {build_type}: {sorted(extra)}")
        if len(passed_tests) != len(REQUIRED_TESTS):
            raise RuntimeError(f"CTest test count mismatch for {build_type}: expected {len(REQUIRED_TESTS)}, got {len(passed_tests)}")

        log_file = output_dir / f"ctest_{build_type.lower()}.log"
        log_file.write_text(res_ctest.stdout, encoding="utf-8")

        return {
            "build_type": build_type,
            "status": "PASS",
            "tests_passed": len(passed_tests),
            "manifest": passed_tests,
            "log_path": str(log_file),
        }


def run(output_dir: Path, require_toolchain: bool = False) -> int:
    output_dir.mkdir(parents=True, exist_ok=True)
    cmake_bin = find_tool("cmake")
    ctest_bin = find_tool("ctest")

    if not cmake_bin or not ctest_bin:
        if require_toolchain:
            print("ERROR: cmake or ctest not found on host and toolchain is required.", file=sys.stderr)
            summary = {
                "step": "ws10-s2-step1-native",
                "status": "FAIL",
                "error": "cmake or ctest toolchain missing on runner host",
                "timestamp": time.time(),
            }
            (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
            return 1
        print("NOTICE: cmake or ctest not found on host. Native CTest runner skipped.", file=sys.stderr)
        summary = {
            "step": "ws10-s2-step1-native",
            "status": "SKIPPED",
            "reason": "cmake or ctest toolchain missing on runner host",
            "timestamp": time.time(),
        }
        (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        return 0

    print(f"WS10-S2 Step 1 Native CTest Runner using cmake={cmake_bin}, ctest={ctest_bin}")
    try:
        debug_res = run_configuration(cmake_bin, ctest_bin, "Debug", output_dir)
        release_res = run_configuration(cmake_bin, ctest_bin, "Release", output_dir)

        summary = {
            "step": "ws10-s2-step1-native",
            "status": "PASS",
            "configurations": {
                "Debug": debug_res,
                "Release": release_res,
            },
            "timestamp": time.time(),
        }
        (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(f"WS10-S2 Step 1 Native CTest PASS: Debug={debug_res['tests_passed']} tests, Release={release_res['tests_passed']} tests")
        return 0
    except Exception as e:
        print(f"ERROR: WS10-S2 Step 1 Native CTest failed: {e}", file=sys.stderr)
        summary = {
            "step": "ws10-s2-step1-native",
            "status": "FAIL",
            "error": str(e),
            "timestamp": time.time(),
        }
        (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        return 1


def main() -> None:
    parser = argparse.ArgumentParser(description="WS10-S2 Step 1 Native CTest Required Runner")
    parser.add_argument("--output-dir", default=str(REPO_ROOT / "ci-artifacts" / "ws10-s2-step1-native"),
                        help="Directory to save test logs and summary.json")
    parser.add_argument("--require-toolchain", action="store_true",
                        help="Fail-closed with non-zero exit code if cmake or ctest toolchain is missing")
    args = parser.parse_args()
    sys.exit(run(Path(args.output_dir), require_toolchain=args.require_toolchain))


if __name__ == "__main__":
    main()

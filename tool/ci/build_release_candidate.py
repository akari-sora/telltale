#!/usr/bin/env python3
"""Build secret-free release candidates on the 9700X GitLab runner."""

from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

RUNNER_ID = 57287642
IMAGE = "docker.io/plugfox/flutter@sha256:9cc3fb4d2c742c21d8bb6ab16eef657810b27ac78429920c6cd644dc8e158e22"


def main() -> None:
    if (
        os.environ.get("CI_PROJECT_ID") != "86385809"
        or os.environ.get("CI_RUNNER_ID") != str(RUNNER_ID)
        or os.environ.get("CI_COMMIT_BRANCH") != "main"
        or os.environ.get("CI_COMMIT_REF_PROTECTED") != "true"
        or os.environ.get("CI_PIPELINE_SOURCE") != "api"
        or os.environ.get("CI_JOB_NAME") != "full-gate"
        or os.environ.get("CI_JOB_IMAGE") != IMAGE
        or "AMD Ryzen 7 9700X" not in Path("/proc/cpuinfo").read_text()
    ):
        raise RuntimeError("Protected main on the pinned 9700X runner required")
    root = Path.cwd()
    source = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    if source != os.environ["CI_COMMIT_SHA"]:
        raise RuntimeError("Source mismatch")
    if subprocess.check_output(["git", "status", "--porcelain"], text=True).strip():
        raise RuntimeError("Dirty candidate source")
    if (root / "android/key.properties").exists():
        raise RuntimeError("Candidate must not receive signing configuration")
    version = re.search(
        r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$",
        (root / "pubspec.yaml").read_text(),
        re.M,
    )
    if version is None:
        raise RuntimeError("Invalid version")
    out = root / "ci-artifacts/release-candidate"
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env["ORG_GRADLE_PROJECT_allowUnsignedRelease"] = "true"
    receipt = {
        "sourceCommit": source,
        "sourceTree": subprocess.check_output(
            ["git", "rev-parse", "HEAD^{tree}"], text=True
        ).strip(),
        "runnerId": RUNNER_ID,
        "jobId": int(os.environ["CI_JOB_ID"]),
        "image": IMAGE,
        "versionName": version[1],
        "bundleVersionCode": int(version[2]),
        "signed": False,
        "builds": [],
        "assets": [],
        "status": "BUILDING",
    }
    for name, args in [
        ("bundle", ["appbundle", "--release", "--flavor", "field"]),
        ("apks", ["apk", "--release", "--flavor", "field", "--split-per-abi"]),
    ]:
        command = ["flutter", "build", *args]
        with (
            (out / f"{name}.stdout").open("w") as stdout,
            (out / f"{name}.stderr").open("w") as stderr,
        ):
            result = subprocess.run(command, env=env, stdout=stdout, stderr=stderr)
        receipt["builds"].append({"command": command, "exitCode": result.returncode})
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        if result.returncode:
            raise RuntimeError("Unsigned candidate build failed")
    assets = [
        (
            root / "build/app/outputs/bundle/fieldRelease/app-field-release.aab",
            f"telltale-v{version[1]}.aab",
        )
    ]
    assets += [
        (
            root / f"build/app/outputs/flutter-apk/app-{abi}-field-release.apk",
            f"telltale-v{version[1]}-{abi}.apk",
        )
        for abi in ["armeabi-v7a", "arm64-v8a", "x86_64"]
    ]
    signer = Path(os.environ["ANDROID_SDK_ROOT"]) / "build-tools/36.0.0/apksigner"
    for src, name in assets:
        with zipfile.ZipFile(src) as archive:
            if archive.testzip() is not None or any(
                re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", n, re.I)
                for n in archive.namelist()
            ):
                raise RuntimeError("Candidate is corrupt or already JAR-signed")
        if (
            src.suffix == ".apk"
            and subprocess.run(
                [str(signer), "verify", str(src)], capture_output=True
            ).returncode
            == 0
        ):
            raise RuntimeError("Candidate APK is already signed")
        shutil.copyfile(src, out / name)
        receipt["assets"].append(
            {
                "file": name,
                "bytes": src.stat().st_size,
                "sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
            }
        )
    receipt["status"] = "PASS"
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(
        "Unsigned unified release candidate built; private signing and device acceptance remain required"
    )


if __name__ == "__main__":
    main()

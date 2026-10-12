#!/usr/bin/env python3
"""
Verify Android Auto / AAOS merged manifest isolation contract.

Verifies:
  AA01-08 carProto merged manifest:
    MUST contain CarAppService
    MUST contain category.IOT
    MUST contain com.google.android.gms.car.application

  Unified field debug/release and carProto merged manifests:
    MUST contain CarAppService, category.IOT, projected metadata and cold-start Application

  rig / wear merged manifests:
    MUST NOT contain projected or AAOS car components

  AA01-10 automotive merged manifest:
    MUST contain CarAppService
    MUST contain com.android.automotive
    MUST contain CarAppActivity
    MUST NOT contain com.google.android.gms.car.application
"""

import os
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]


def find_manifest(candidates):
    for rel in candidates:
        p = ROOT / rel
        if p.is_file():
            return p
    return None


def ensure_manifests():
    candidates_car = [
        "build/app/intermediates/merged_manifest/carProtoDebug/processCarProtoDebugMainManifest/AndroidManifest.xml",
        "build/app/intermediates/merged_manifests/carProtoDebug/processCarProtoDebugManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifest/carProtoDebug/processCarProtoDebugMainManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifests/carProtoDebug/processCarProtoDebugManifest/AndroidManifest.xml",
    ]
    candidates_field = [
        "build/app/intermediates/merged_manifest/fieldDebug/processFieldDebugMainManifest/AndroidManifest.xml",
        "build/app/intermediates/merged_manifests/fieldDebug/processFieldDebugManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifest/fieldDebug/processFieldDebugMainManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifests/fieldDebug/processFieldDebugManifest/AndroidManifest.xml",
    ]
    candidates_auto = [
        "build/automotive/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml",
        "build/automotive/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml",
        "android/automotive/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml",
        "android/automotive/build/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml",
    ]
    candidates_rig = [
        "build/app/intermediates/merged_manifest/rigDebug/processRigDebugMainManifest/AndroidManifest.xml",
        "build/app/intermediates/merged_manifests/rigDebug/processRigDebugManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifest/rigDebug/processRigDebugMainManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifests/rigDebug/processRigDebugManifest/AndroidManifest.xml",
    ]
    candidates_wear = [
        "build/app/intermediates/merged_manifest/wearDebug/processWearDebugMainManifest/AndroidManifest.xml",
        "build/app/intermediates/merged_manifests/wearDebug/processWearDebugManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifest/wearDebug/processWearDebugMainManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifests/wearDebug/processWearDebugManifest/AndroidManifest.xml",
    ]

    candidates_field_release = [
        "build/app/intermediates/merged_manifest/fieldRelease/processFieldReleaseMainManifest/AndroidManifest.xml",
        "build/app/intermediates/merged_manifests/fieldRelease/processFieldReleaseManifest/arm64-v8a/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifest/fieldRelease/processFieldReleaseMainManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifests/fieldRelease/processFieldReleaseManifest/arm64-v8a/AndroidManifest.xml",
    ]

    p_car = find_manifest(candidates_car)
    p_field = find_manifest(candidates_field)
    p_auto = find_manifest(candidates_auto)
    p_field_release = find_manifest(candidates_field_release)
    p_rig = find_manifest(candidates_rig)
    p_wear = find_manifest(candidates_wear)

    if not (p_car and p_field and p_auto and p_field_release and p_rig and p_wear):
        print("[INFO] One or more merged manifests missing; invoking Gradle to generate them...")
        cmd = [
            "./android/gradlew",
            "-p",
            "android",
            ":app:processFieldDebugMainManifest",
            ":app:processFieldReleaseMainManifest",
            ":app:processCarProtoDebugMainManifest",
            ":app:processRigDebugMainManifest",
            ":app:processWearDebugMainManifest",
            ":automotive:processDebugMainManifest",
        ]
        res = subprocess.run(cmd, cwd=str(ROOT))
        if res.returncode != 0:
            print(f"[ERROR] Gradle failed with exit code {res.returncode}", file=sys.stderr)
            sys.exit(res.returncode)

        p_car = find_manifest(candidates_car)
        p_field = find_manifest(candidates_field)
        p_auto = find_manifest(candidates_auto)
        p_field_release = find_manifest(candidates_field_release)
        p_rig = find_manifest(candidates_rig)
        p_wear = find_manifest(candidates_wear)

    if not p_car:
        raise FileNotFoundError(f"carProto merged manifest not found in: {candidates_car}")
    if not p_field:
        raise FileNotFoundError(f"field merged manifest not found in: {candidates_field}")
    if not p_auto:
        raise FileNotFoundError(f"automotive merged manifest not found in: {candidates_auto}")
    if not p_field_release:
        raise FileNotFoundError(f"fieldRelease merged manifest not found in: {candidates_field_release}")
    if not p_rig:
        raise FileNotFoundError(f"rig merged manifest not found in: {candidates_rig}")
    if not p_wear:
        raise FileNotFoundError(f"wear merged manifest not found in: {candidates_wear}")

    return p_car, p_field, p_auto, p_field_release, p_rig, p_wear


def extract_manifest_tokens(path: Path) -> set[str]:
    """Parse AndroidManifest XML and extract all active tags, attributes, and text.

    Comments are excluded by ElementTree, preventing non-code commentary from
    triggering false-positive leak errors while ensuring all real XML tags,
    intent filters, categories, and metadata are strictly inspected.
    """
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        tokens = set()
        for elem in root.iter():
            tokens.add(elem.tag)
            for k, v in elem.attrib.items():
                tokens.add(k)
                tokens.add(v)
            if elem.text and elem.text.strip():
                tokens.add(elem.text.strip())
        return tokens
    except ET.ParseError as exc:
        raise RuntimeError(f"Failed to parse XML from {path}: {exc}")



def verify_manifest(name: str, path: Path, must_contain: list[str], must_not_contain: list[str]) -> list[str]:
    errors = []
    tokens = extract_manifest_tokens(path)
    display_path = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path.name
    print(f"\n--- Checking {name} merged manifest: {display_path} ---")

    for token in must_contain:
        if not any(token in t for t in tokens):
            err = f"[{name} FAIL] Expected token {token!r} NOT found in merged manifest {path}"
            print(f"  ❌ {err}")
            errors.append(err)
        else:
            print(f"  ✅ MUST contain: {token}")

    for token in must_not_contain:
        if any(token in t for t in tokens):
            err = f"[{name} FAIL] Forbidden token {token!r} leaked into merged manifest {path}"
            print(f"  ❌ {err}")
            errors.append(err)
        else:
            print(f"  ✅ MUST NOT contain: {token}")

    return errors


def main():
    print("=== Verifying Car Merged Manifest Isolation ===")
    p_car, p_field, p_auto, p_field_release, p_rig, p_wear = ensure_manifests()

    all_errors = []

    # AA01-08 / AA05-04 carProto merged manifest:
    # MUST contain CarAppService, category.IOT, com.google.android.gms.car.application
    # MUST contain com.google.android.gms.permission.CAR_SPEED
    # MUST NOT contain AAOS specific permissions
    all_errors.extend(
        verify_manifest(
            name="AA01-08 / AA05-04 carProto",
            path=p_car,
            must_contain=[
                "CarAppService",
                "category.IOT",
                "com.google.android.gms.car.application",
                "com.google.android.gms.permission.CAR_SPEED",
                "ProjectedTelltaleApplication",
            ],
            must_not_contain=[
                "com.android.automotive",
                "CarAppActivity",
                "android.car.permission.CAR_SPEED",
                "android.car.permission.READ_CAR_DISPLAY_UNITS",
            ],
        )
    )

    projected_required = [
        "CarAppService",
        "category.IOT",
        "com.google.android.gms.car.application",
        "com.google.android.gms.permission.CAR_SPEED",
        "ProjectedTelltaleApplication",
    ]
    projected_forbidden = [
        "com.android.automotive",
        "CarAppActivity",
        "android.car.permission.CAR_SPEED",
        "android.car.permission.READ_CAR_DISPLAY_UNITS",
    ]
    for name, path in (
        ("unified fieldDebug", p_field),
        ("unified fieldRelease", p_field_release),
    ):
        all_errors.extend(
            verify_manifest(
                name=name,
                path=path,
                must_contain=projected_required,
                must_not_contain=projected_forbidden,
            )
        )

    non_projection_forbidden = projected_required + projected_forbidden
    for name, path in (("rigDebug", p_rig), ("wearDebug", p_wear)):
        all_errors.extend(
            verify_manifest(
                name=name,
                path=path,
                must_contain=[],
                must_not_contain=non_projection_forbidden,
            )
        )

    # AA01-10 / AA05-05 automotive merged manifest:
    # MUST contain CarAppService, com.android.automotive, CarAppActivity
    # MUST contain android.car.permission.CAR_SPEED, android.car.permission.READ_CAR_DISPLAY_UNITS
    # MUST NOT contain com.google.android.gms.car.application or Google CAR_SPEED
    all_errors.extend(
        verify_manifest(
            name="AA01-10 / AA05-05 automotive",
            path=p_auto,
            must_contain=[
                "CarAppService",
                "com.android.automotive",
                "CarAppActivity",
                "android.car.permission.CAR_SPEED",
                "android.car.permission.READ_CAR_DISPLAY_UNITS",
            ],
            must_not_contain=[
                "com.google.android.gms.car.application",
                "com.google.android.gms.permission.CAR_SPEED",
            ],
        )
    )

    print("\n" + "=" * 50)
    if all_errors:
        print(f"FAILED: {len(all_errors)} isolation contract violation(s) found:", file=sys.stderr)
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    print("SUCCESS: All merged manifest isolation contracts verified! 🚀")
    sys.exit(0)


if __name__ == "__main__":
    main()

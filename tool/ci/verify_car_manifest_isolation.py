#!/usr/bin/env python3
"""
Verify Android Auto / AAOS merged manifest isolation contract.

Verifies:
  AA01-08 carProto merged manifest:
    MUST contain CarAppService
    MUST contain category.IOT
    MUST contain com.google.android.gms.car.application

  AA01-09 field (production) merged manifest:
    MUST NOT contain CarAppService
    MUST NOT contain category.IOT
    MUST NOT contain com.google.android.gms.car.application

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

    p_car = find_manifest(candidates_car)
    p_field = find_manifest(candidates_field)
    p_auto = find_manifest(candidates_auto)

    if not (p_car and p_field and p_auto):
        print("[INFO] One or more merged manifests missing; invoking Gradle to generate them...")
        cmd = [
            "./android/gradlew",
            "-p",
            "android",
            ":app:processFieldDebugMainManifest",
            ":app:processCarProtoDebugMainManifest",
            ":automotive:processDebugMainManifest",
        ]
        res = subprocess.run(cmd, cwd=str(ROOT))
        if res.returncode != 0:
            print(f"[ERROR] Gradle failed with exit code {res.returncode}", file=sys.stderr)
            sys.exit(res.returncode)

        p_car = find_manifest(candidates_car)
        p_field = find_manifest(candidates_field)
        p_auto = find_manifest(candidates_auto)

    if not p_car:
        raise FileNotFoundError(f"carProto merged manifest not found in: {candidates_car}")
    if not p_field:
        raise FileNotFoundError(f"field merged manifest not found in: {candidates_field}")
    if not p_auto:
        raise FileNotFoundError(f"automotive merged manifest not found in: {candidates_auto}")

    return p_car, p_field, p_auto


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
    except ET.ParseError:
        return set(path.read_text(encoding="utf-8").split())


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
    p_car, p_field, p_auto = ensure_manifests()

    all_errors = []

    # AA01-08 carProto merged manifest:
    # MUST contain CarAppService
    # MUST contain category.IOT
    # MUST contain com.google.android.gms.car.application
    all_errors.extend(
        verify_manifest(
            name="AA01-08 carProto",
            path=p_car,
            must_contain=[
                "CarAppService",
                "category.IOT",
                "com.google.android.gms.car.application",
            ],
            must_not_contain=[
                "com.android.automotive",
                "CarAppActivity",
            ],
        )
    )

    # AA01-09 field merged manifest:
    # MUST NOT contain CarAppService
    # MUST NOT contain category.IOT
    # MUST NOT contain com.google.android.gms.car.application
    all_errors.extend(
        verify_manifest(
            name="AA01-09 field (production)",
            path=p_field,
            must_contain=[],
            must_not_contain=[
                "CarAppService",
                "category.IOT",
                "com.google.android.gms.car.application",
                "com.android.automotive",
                "CarAppActivity",
            ],
        )
    )

    # Check fieldRelease merged manifest if present
    candidates_field_release = [
        "build/app/intermediates/merged_manifest/fieldRelease/processFieldReleaseMainManifest/AndroidManifest.xml",
        "build/app/intermediates/merged_manifests/fieldRelease/processFieldReleaseManifest/arm64-v8a/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifest/fieldRelease/processFieldReleaseMainManifest/AndroidManifest.xml",
        "android/app/build/intermediates/merged_manifests/fieldRelease/processFieldReleaseManifest/arm64-v8a/AndroidManifest.xml",
    ]
    p_field_release = find_manifest(candidates_field_release)
    if p_field_release:
        all_errors.extend(
            verify_manifest(
                name="AA01-09 fieldRelease (production)",
                path=p_field_release,
                must_contain=[],
                must_not_contain=[
                    "CarAppService",
                    "category.IOT",
                    "com.google.android.gms.car.application",
                    "com.android.automotive",
                    "CarAppActivity",
                ],
            )
        )

    # AA01-10 automotive merged manifest:
    # MUST contain CarAppService
    # MUST contain com.android.automotive
    # MUST contain CarAppActivity
    # MUST NOT contain com.google.android.gms.car.application
    all_errors.extend(
        verify_manifest(
            name="AA01-10 automotive",
            path=p_auto,
            must_contain=[
                "CarAppService",
                "com.android.automotive",
                "CarAppActivity",
            ],
            must_not_contain=[
                "com.google.android.gms.car.application",
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

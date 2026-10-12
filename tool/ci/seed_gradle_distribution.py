#!/usr/bin/env python3
"""Pre-seed the Gradle wrapper distribution from a fast mirror.

HiNet's route to Fastly (services.gradle.org -> GitHub release assets) has
dropped to a few hundred KB/s since September 2026, so a fresh CI container can
spend most of its one-hour budget downloading the wrapper distribution. This
places the exact zip the wrapper expects into its cache, but only after its
SHA-256 matches `distributionSha256Sum` from gradle-wrapper.properties. Any
failure leaves the cache untouched and the wrapper downloads from the official
URL as before, so the result can only be the pinned distribution.
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import sys
import tempfile
import urllib.request

MIRRORS = (
    "https://mirrors.cloud.tencent.com/gradle/{name}",
    "https://mirrors.aliyun.com/macports/distfiles/gradle/{name}",
)
TIMEOUT_SECONDS = 30
MAX_BYTES = 512 * 1024 * 1024


def read_properties(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith(("#", "!")) or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().replace("\\:", ":")
    return values


def base36(value: int) -> str:
    digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    out = ""
    while value:
        value, rem = divmod(value, 36)
        out = digits[rem] + out
    return out or "0"


def wrapper_zip_path(gradle_home: Path, url: str, zip_store_path: str) -> Path:
    """Mirror Gradle's PathAssembler: <zipStorePath>/<dist>/<base36 md5(url)>/<zip>."""
    name = url.rsplit("/", 1)[-1]
    dist = name[: -len(".zip")] if name.endswith(".zip") else name
    url_hash = base36(int.from_bytes(hashlib.md5(url.encode("utf-8")).digest(), "big"))
    return gradle_home / zip_store_path / dist / url_hash / name


def fetch(url: str, target: Path, expected_sha256: str) -> bool:
    digest = hashlib.sha256()
    size = 0
    try:
        with urllib.request.urlopen(url, timeout=TIMEOUT_SECONDS) as response, target.open("wb") as out:
            while chunk := response.read(1024 * 1024):
                size += len(chunk)
                if size > MAX_BYTES:
                    return False
                digest.update(chunk)
                out.write(chunk)
    except OSError as error:
        print(f"seed-gradle: {url}: {error}")
        return False
    if digest.hexdigest() != expected_sha256:
        print(f"seed-gradle: {url}: SHA-256 mismatch, discarded")
        return False
    return True


def seed(properties: Path, gradle_home: Path, mirrors=MIRRORS) -> Path | None:
    props = read_properties(properties)
    url = props.get("distributionUrl", "")
    expected = props.get("distributionSha256Sum", "").lower()
    if (
        props.get("zipStoreBase", "GRADLE_USER_HOME") != "GRADLE_USER_HOME"
        or not url.startswith("https://services.gradle.org/distributions/")
        or len(expected) != 64
    ):
        print("seed-gradle: unsupported wrapper configuration, skipped")
        return None
    destination = wrapper_zip_path(gradle_home, url, props.get("zipStorePath", "wrapper/dists"))
    if destination.is_file():
        print(f"seed-gradle: {destination.name} already cached")
        return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    name = destination.name
    with tempfile.TemporaryDirectory(dir=destination.parent) as staging:
        part = Path(staging) / name
        for template in mirrors:
            if fetch(template.format(name=name), part, expected):
                os.replace(part, destination)
                break
        else:
            print("seed-gradle: no mirror delivered the pinned distribution; wrapper will download")
            return None
    print(f"seed-gradle: seeded {name} (sha256 {expected[:12]}…) from mirror")
    return destination


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: seed_gradle_distribution.py <gradle-wrapper.properties> <gradle-user-home>")
        return 2
    try:
        seed(Path(argv[1]), Path(argv[2]))
    except Exception as error:  # never block the gate; the wrapper still verifies
        print(f"seed-gradle: skipped after error: {error}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

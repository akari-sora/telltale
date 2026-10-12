#!/usr/bin/env python3
"""Sign an exact-source release candidate on the private Ryzen 9700X host."""

from __future__ import annotations

import argparse
import base64
import binascii
from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path
import pwd
import re
import stat
import subprocess
import sys
import tempfile
from typing import Any, Mapping, Sequence, cast
import xml.etree.ElementTree as ET
import zipfile

MAINTAINER_CERT = "362133c004bee5e4f458f77d4a5d199948a3c5cdb9f0868be27d6f5d9109a579"
RUNNER_ID = 57287642
PROJECT_ID = "86385809"
IMAGE = "docker.io/plugfox/flutter@sha256:9cc3fb4d2c742c21d8bb6ab16eef657810b27ac78429920c6cd644dc8e158e22"
PACKAGE = "com.cbstudio.telltale"
VERSION = "1.0.19"
VERSION_CODE = 200
CAR_SERVICE = "com.cbstudio.telltale.car.TelltaleCarAppService"
CAR_ACTION = "androidx.car.app.CarAppService"
CAR_CATEGORY = "androidx.car.app.category.IOT"
CAR_METADATA = "com.google.android.gms.car.application"
CAR_METADATA_RESOURCE = "@xml/automotive_app_desc"
BUNDLETOOL_VERSION = "1.18.3"
TOOLCHAIN_RECEIPT_SHA256 = (
    "df6548dcbde6322089e39b9b1212c54bb7d839eb3f494a9ecceaa188d6be4795"
)
JAVA_HOME = Path("/usr/lib/jvm/java-17-openjdk-amd64")
EXPECTED_TOOL_HASHES = {
    "java": "e363cce82477c5f19cab72d432defe96fa1c69503353c3e5e9660243e2030883",
    "keytool": "6a00bd6f3383d9af0486aeb00763c0c40ab879d4279659d05b71ed1905c8984f",
    "jarsigner": "904fb247d5fa0fd68e484bbbda1aff1a722a7bbf1c512de80e7212dea8720794",
    "aapt": "c076aeeee8bd3ce58395a093747202265ab80c6c12e59358f598a30a81fde13b",
    "apksigner": "b47549e373b895ce6ca620d0c7887e674d9615ffa837a86ac601dcfd04adb0f0",
    "zipalign": "c5f559e946de5a9e7d58792181db20383b228877812136bc469d97ae00a43b0a",
    "apksigner.jar": "3716d9311e55d2b0918a2fd9d54ba9e406c5f6abeea700b287f11259bc163dec",
    "bundletool": "a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29",
}
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


@dataclass(frozen=True)
class Toolchain:
    java: Path
    keytool: Path
    jarsigner: Path
    aapt: Path
    apksigner: Path
    zipalign: Path
    bundletool: Path
    environment: dict[str, str]


@dataclass
class ManifestNode:
    name: str
    attributes: dict[str, str] = field(default_factory=dict)
    children: list[ManifestNode] = field(default_factory=list)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def clean_environment(extra: Mapping[str, str] | None = None) -> dict[str, str]:
    """Build a small environment that cannot inject code into Java/native tools."""
    env = {
        "HOME": pwd.getpwuid(os.getuid()).pw_dir,
        "JAVA_HOME": str(JAVA_HOME),
        "PATH": f"{JAVA_HOME / 'bin'}:/usr/bin:/bin",
        "LANG": "C.UTF-8",
        "LC_ALL": "C.UTF-8",
    }
    if extra and set(extra) != {
        "TELLTALE_STORE_PASSWORD",
        "TELLTALE_KEY_PASSWORD",
    }:
        raise RuntimeError("Unexpected environment override")
    if extra:
        env.update(extra)
    return env


def _validate_live_record(record: Mapping[str, Any]) -> Path:
    required = {"path", "canonicalPath", "uid", "gid", "mode", "bytes", "sha256"}
    if not required <= record.keys():
        raise RuntimeError("Incomplete toolchain file record")
    path = Path(record["path"])
    if not path.is_absolute() or path.is_symlink() or not path.is_file():
        raise RuntimeError("Toolchain path is not a regular absolute file")
    resolved = path.resolve(strict=True)
    info = path.stat()
    if (
        str(resolved) != record["canonicalPath"]
        or info.st_uid != record["uid"]
        or info.st_gid != record["gid"]
        or oct(stat.S_IMODE(info.st_mode)) != record["mode"]
        or info.st_size != record["bytes"]
        or sha256(path) != record["sha256"]
        or stat.S_IMODE(info.st_mode) & 0o022
    ):
        raise RuntimeError(f"Toolchain file changed: {path}")
    return resolved


def _run_version(command: Sequence[str], env: Mapping[str, str]) -> str:
    result = subprocess.run(
        command, capture_output=True, text=True, env=env, check=True
    )
    return (result.stdout + result.stderr).strip()


def validate_toolchain(receipt_path: Path, tools_path: Path) -> Toolchain:
    """Validate every executable/library before any signing secret is read."""
    if receipt_path.is_symlink() or not receipt_path.is_file():
        raise RuntimeError("Toolchain receipt must be a regular file")
    receipt_stat = receipt_path.stat()
    if receipt_stat.st_uid != os.getuid() or stat.S_IMODE(receipt_stat.st_mode) & 0o077:
        raise RuntimeError("Toolchain receipt must be private and caller-owned")
    if sha256(receipt_path) != TOOLCHAIN_RECEIPT_SHA256:
        raise RuntimeError("Wrong toolchain receipt")
    receipt: dict[str, Any] = json.loads(receipt_path.read_text())
    if (
        receipt.get("status") != "PASS_PINNED_9700X_SIGNING_VALIDATION_TOOLCHAIN_V2"
        or receipt.get("uid") != os.getuid()
        or receipt.get("dockerUsed") is not False
        or receipt.get("hostSudoUsed") is not False
        or receipt.get("signingSecretUsed") is not False
        or receipt.get("sdkRootMode") != "0o700"
    ):
        raise RuntimeError("Untrusted toolchain receipt status")
    sdk_root = Path(receipt["sdkRoot"])
    build_tools = sdk_root / "build-tools" / "36.0.0"
    if tools_path.resolve(strict=True) != build_tools.resolve(strict=True):
        raise RuntimeError("Unexpected Android build-tools directory")
    sdk_stat = sdk_root.stat()
    if (
        sdk_root.is_symlink()
        or sdk_stat.st_uid != os.getuid()
        or stat.S_IMODE(sdk_stat.st_mode) != 0o700
    ):
        raise RuntimeError("Android SDK root is not private")

    jdk_records = receipt["jdk"]["tools"]
    jdk = {
        name: _validate_live_record(jdk_records[name])
        for name in ("java", "keytool", "jarsigner")
    }
    for name, path in jdk.items():
        if (
            path != JAVA_HOME / "bin" / name
            or sha256(path) != EXPECTED_TOOL_HASHES[name]
            or path.stat().st_uid != 0
        ):
            raise RuntimeError(f"Wrong trusted JDK {name}")

    android_records = receipt["androidBuildTools"]["files"]
    validated_android = {
        Path(item["path"]).relative_to(build_tools).as_posix(): _validate_live_record(
            item
        )
        for item in android_records
    }
    for records in receipt["androidBuildTools"]["runtimeLinkedLibraries"].values():
        for item in records:
            _validate_live_record(item)
    critical = {
        "aapt": "aapt",
        "apksigner": "apksigner",
        "zipalign": "zipalign",
        "apksigner.jar": "lib/apksigner.jar",
    }
    for key, relative in critical.items():
        critical_path = validated_android.get(relative)
        if critical_path is None or sha256(critical_path) != EXPECTED_TOOL_HASHES[key]:
            raise RuntimeError(f"Wrong Android tool {key}")

    bundle_record = receipt["bundletool"]["file"]
    bundletool = _validate_live_record(bundle_record)
    fixture = receipt["strictJarsignerTrustAnchorFixture"]
    if (
        receipt["bundletool"].get("version") != BUNDLETOOL_VERSION
        or sha256(bundletool) != EXPECTED_TOOL_HASHES["bundletool"]
        or fixture.get("status") != "PASS"
        or fixture.get("exitCode") != 0
        or fixture.get("reportedTrustedCertificate") is not True
        or fixture.get("productionCredentialUsed") is not False
        or fixture.get("temporaryFixtureRemoved") is not True
    ):
        raise RuntimeError("Untrusted bundletool or jarsigner fixture")

    env = clean_environment()
    for name in ("java", "keytool", "jarsigner"):
        version_argument = "-version" if name == "java" else "-J-version"
        observed = _run_version([str(jdk[name]), version_argument], env)
        if (
            observed
            != receipt["jdk"][
                f"{name}RuntimeVersion" if name != "java" else "runtimeVersion"
            ]
        ):
            raise RuntimeError(f"JDK runtime changed: {name}")
    if (
        _run_version([str(jdk["java"]), "-jar", str(bundletool), "version"], env)
        != BUNDLETOOL_VERSION
    ):
        raise RuntimeError("bundletool runtime changed")
    return Toolchain(
        java=jdk["java"],
        keytool=jdk["keytool"],
        jarsigner=jdk["jarsigner"],
        aapt=validated_android["aapt"],
        apksigner=validated_android["apksigner"],
        zipalign=validated_android["zipalign"],
        bundletool=bundletool,
        environment=env,
    )


def validate_job(job: dict[str, Any], source: str, name: str) -> None:
    pipeline = job.get("pipeline", {})
    if (
        job.get("status") != "success"
        or job.get("name") != name
        or job.get("ref") != "main"
        or job.get("tag") is not False
        or job.get("commit", {}).get("id") != source
        or pipeline.get("project_id") != int(PROJECT_ID)
        or pipeline.get("sha") != source
        or pipeline.get("ref") != "main"
        or pipeline.get("status") != "success"
        or pipeline.get("source") not in {"push", "api", "web"}
        or job.get("runner", {}).get("id") != RUNNER_ID
    ):
        raise RuntimeError("Exact-source successful 9700X job required")


def validate_gate(job: dict[str, Any], source: str) -> None:
    validate_job(job, source, "full-gate")


def validate_candidate_job(job: dict[str, Any], source: str) -> None:
    validate_gate(job, source)
    if job["pipeline"]["source"] != "api":
        raise RuntimeError("Candidate must be maintainer-dispatched")


def certificate(output: str, pattern: str) -> str:
    matches = re.findall(pattern, output)
    if len(matches) != 1:
        raise RuntimeError("Expected exactly one artifact signing certificate")
    cert = cast(str, matches[0]).replace(":", "").lower()
    if cert != MAINTAINER_CERT:
        raise RuntimeError("Wrong signing certificate")
    return cert


def validate_signing(signing: object) -> dict[str, str]:
    if not isinstance(signing, dict) or set(signing) != {
        "keystoreBase64",
        "storePassword",
        "keyPassword",
        "keyAlias",
    }:
        raise RuntimeError("Invalid signing payload fields")
    values = {key: value for key, value in signing.items() if isinstance(value, str)}
    if len(values) != 4 or any(not value or "\0" in value for value in values.values()):
        raise RuntimeError("Invalid signing payload values")
    if not re.fullmatch(r"[A-Za-z0-9_.-]{1,128}", values["keyAlias"]):
        raise RuntimeError("Invalid key alias")
    if len(values["keystoreBase64"]) > 4 * 1024 * 1024:
        raise RuntimeError("Keystore payload too large")
    return values


def _android_name(element: ET.Element) -> str | None:
    return element.get(ANDROID_NS + "name")


def validate_aab_manifest(xml: str, version: str, code: int) -> None:
    root = ET.fromstring(xml)
    if (
        root.tag != "manifest"
        or root.get("package") != PACKAGE
        or root.get(ANDROID_NS + "versionName") != version
        or root.get(ANDROID_NS + "versionCode") != str(code)
    ):
        raise RuntimeError("Unexpected AAB identity/version")
    applications = root.findall("application")
    if len(applications) != 1:
        raise RuntimeError("AAB must have exactly one application")
    app = applications[0]
    metadata = [
        node for node in app.findall("meta-data") if _android_name(node) == CAR_METADATA
    ]
    services = [
        node for node in app.findall("service") if _android_name(node) == CAR_SERVICE
    ]
    if (
        len(metadata) != 1
        or metadata[0].get(ANDROID_NS + "resource") != CAR_METADATA_RESOURCE
        or len(services) != 1
    ):
        raise RuntimeError("AAB Android Auto metadata/service mismatch")
    service = services[0]
    filters = service.findall("intent-filter")
    if service.get(ANDROID_NS + "exported") != "true" or len(filters) != 1:
        raise RuntimeError("AAB Android Auto service exposure mismatch")
    actions = [_android_name(node) for node in filters[0].findall("action")]
    categories = [_android_name(node) for node in filters[0].findall("category")]
    if (
        actions != [CAR_ACTION]
        or categories != [CAR_CATEGORY]
        or len(list(filters[0])) != 2
    ):
        raise RuntimeError("AAB Android Auto intent mismatch")


def parse_aapt_xmltree(output: str) -> ManifestNode:
    root: ManifestNode | None = None
    stack: list[tuple[int, ManifestNode]] = []
    element_pattern = re.compile(r"^(\s*)E:\s+([^\s(]+)")
    attribute_pattern = re.compile(r"^\s*A:\s+android:([^=(]+)(?:\([^)]*\))?=(.*)$")
    for line in output.splitlines():
        element_match = element_pattern.match(line)
        if element_match:
            indent = len(element_match[1])
            node = ManifestNode(element_match[2])
            while stack and stack[-1][0] >= indent:
                stack.pop()
            if stack:
                stack[-1][1].children.append(node)
            elif root is None:
                root = node
            else:
                raise RuntimeError("Multiple manifest roots")
            stack.append((indent, node))
            continue
        attribute_match = attribute_pattern.match(line)
        if attribute_match and stack:
            encoded = attribute_match[2].strip()
            raw = re.search(r'\(Raw: "([^"]*)"\)', encoded)
            quoted = re.match(r'"([^"]*)"', encoded)
            resource = re.match(r"(@0x[0-9a-fA-F]{8})", encoded)
            if raw:
                value = raw[1]
            elif quoted:
                value = quoted[1]
            elif resource:
                value = resource[1]
            elif encoded.endswith("0xffffffff"):
                value = "true"
            elif encoded.endswith("0x0"):
                value = "false"
            else:
                value = encoded
            stack[-1][1].attributes[attribute_match[1]] = value
    if root is None:
        raise RuntimeError("No APK manifest root")
    return root


def _children(node: ManifestNode, name: str) -> list[ManifestNode]:
    return [child for child in node.children if child.name == name]


def validate_apk_manifest(xmltree: str, resources: str) -> None:
    root = parse_aapt_xmltree(xmltree)
    applications = _children(root, "application")
    if root.name != "manifest" or len(applications) != 1:
        raise RuntimeError("APK manifest shape mismatch")
    app = applications[0]
    metadata = [
        node
        for node in _children(app, "meta-data")
        if node.attributes.get("name") == CAR_METADATA
    ]
    services = [
        node
        for node in _children(app, "service")
        if node.attributes.get("name") == CAR_SERVICE
    ]
    if len(metadata) != 1 or len(services) != 1:
        raise RuntimeError("APK Android Auto metadata/service mismatch")
    resource = metadata[0].attributes.get("resource", "")
    if resource != CAR_METADATA_RESOURCE:
        resource_id = re.fullmatch(r"@0x([0-9a-fA-F]{8})", resource)
        if (
            resource_id is None
            or re.search(
                rf"spec resource 0x{resource_id[1]}\s+{re.escape(PACKAGE)}:xml/automotive_app_desc\b",
                resources,
            )
            is None
        ):
            raise RuntimeError("APK Android Auto metadata resource mismatch")
    service = services[0]
    filters = _children(service, "intent-filter")
    if service.attributes.get("exported") != "true" or len(filters) != 1:
        raise RuntimeError("APK Android Auto service exposure mismatch")
    actions = [node.attributes.get("name") for node in _children(filters[0], "action")]
    categories = [
        node.attributes.get("name") for node in _children(filters[0], "category")
    ]
    if (
        actions != [CAR_ACTION]
        or categories != [CAR_CATEGORY]
        or len(filters[0].children) != 2
    ):
        raise RuntimeError("APK Android Auto intent mismatch")


def expected_apk_code(filename: str, version: str, base_code: int) -> int:
    suffixes = {"armeabi-v7a": 1, "arm64-v8a": 2, "x86_64": 3}
    for abi, suffix in suffixes.items():
        if filename == f"telltale-v{version}-{abi}.apk":
            return base_code * 10 + suffix
    raise RuntimeError("Unexpected APK filename")


def validate_unsigned_identity(
    path: Path, toolchain: Toolchain, version: str, code: int
) -> None:
    env = toolchain.environment
    if path.suffix == ".aab":
        xml = subprocess.check_output(
            [
                str(toolchain.java),
                "-jar",
                str(toolchain.bundletool),
                "dump",
                "manifest",
                f"--bundle={path}",
                "--module=base",
            ],
            text=True,
            env=env,
        )
        validate_aab_manifest(xml, version, code)
        return
    badging = subprocess.check_output(
        [str(toolchain.aapt), "dump", "badging", str(path)], text=True, env=env
    )
    package = re.search(
        r"package: name='([^']+)' versionCode='([0-9]+)' versionName='([^']+)'", badging
    )
    if (
        package is None
        or package[1] != PACKAGE
        or int(package[2]) != expected_apk_code(path.name, version, code)
        or package[3] != version
    ):
        raise RuntimeError("Unexpected APK identity/version")
    xmltree = subprocess.check_output(
        [str(toolchain.aapt), "dump", "xmltree", str(path), "AndroidManifest.xml"],
        text=True,
        env=env,
    )
    resources = subprocess.check_output(
        [str(toolchain.aapt), "dump", "resources", str(path)], text=True, env=env
    )
    validate_apk_manifest(xmltree, resources)


def jarsigner_verify_command(
    toolchain: Toolchain, path: Path, key: Path, alias: str
) -> list[str]:
    return [
        str(toolchain.jarsigner),
        "-verify",
        "-strict",
        "-keystore",
        str(key),
        "-storepass:env",
        "TELLTALE_STORE_PASSWORD",
        "-verbose:summary",
        "-certs",
        str(path),
        alias,
    ]


def validate_candidate_asset(
    src: Path,
    asset: Mapping[str, Any],
    toolchain: Toolchain,
    version: str,
    code: int,
) -> None:
    if (
        src.is_symlink()
        or not src.is_file()
        or src.stat().st_size != asset["bytes"]
        or sha256(src) != asset["sha256"]
    ):
        raise RuntimeError("Candidate checksum mismatch")
    with zipfile.ZipFile(src) as archive:
        signed_members = any(
            re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", member, re.I)
            for member in archive.namelist()
        )
        if archive.testzip() is not None or signed_members:
            raise RuntimeError("Candidate corrupt or JAR-signed")
    if (
        src.suffix == ".apk"
        and subprocess.run(
            [str(toolchain.apksigner), "verify", str(src)],
            capture_output=True,
            env=toolchain.environment,
        ).returncode
        == 0
    ):
        raise RuntimeError("Candidate APK is already signed")
    validate_unsigned_identity(src, toolchain, version, code)


def verify_artifact(
    path: Path,
    toolchain: Toolchain,
    version: str,
    code: int,
    env: Mapping[str, str],
    key: Path,
    alias: str,
) -> None:
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Artifact CRC failure")
    if path.suffix == ".aab":
        command = jarsigner_verify_command(toolchain, path, key, alias)
        verified = subprocess.run(
            command, capture_output=True, text=True, env=env, check=True
        )
        output = verified.stdout + verified.stderr
        if "jar verified." not in output or "[trusted certificate]" not in output:
            raise RuntimeError("AAB strict trust-anchor verification failed")
        result = subprocess.check_output(
            [str(toolchain.keytool), "-printcert", "-jarfile", str(path)],
            text=True,
            env=env,
        )
        certificate(result, r"SHA256:\s*([A-Fa-f0-9:]+)")
    else:
        result = subprocess.check_output(
            [
                str(toolchain.apksigner),
                "verify",
                "--verbose",
                "--print-certs",
                str(path),
            ],
            text=True,
            env=env,
        )
        certificate(result, r"certificate SHA-256 digest:\s*([a-fA-F0-9]+)")
        subprocess.run(
            [str(toolchain.zipalign), "-c", "-P", "16", "4", str(path)],
            capture_output=True,
            env=env,
            check=True,
        )
    validate_unsigned_identity(path, toolchain, version, code)


def sign(args: argparse.Namespace, signing_value: object, toolchain: Toolchain) -> None:
    signing = validate_signing(signing_value)
    if not __debug__ or "AMD Ryzen 7 9700X" not in Path("/proc/cpuinfo").read_text():
        raise RuntimeError("Private signing must run on the 9700X")
    if not re.fullmatch(r"[0-9a-f]{40}", args.source):
        raise RuntimeError("Invalid source commit")
    gate: dict[str, Any] = json.loads(args.gate.read_text())
    validate_candidate_job(gate, args.source)
    candidate: dict[str, Any] = json.loads(
        (args.candidate / "receipt.json").read_text()
    )
    if (
        candidate.get("sourceCommit") != args.source
        or candidate.get("runnerId") != RUNNER_ID
        or candidate.get("jobId") != gate["id"]
        or candidate.get("image") != IMAGE
        or candidate.get("signed") is not False
        or candidate.get("status") != "PASS"
        or len(candidate.get("builds", [])) != 2
        or any(build.get("exitCode") != 0 for build in candidate["builds"])
        or candidate.get("versionName") != VERSION
        or candidate.get("bundleVersionCode") != VERSION_CODE
    ):
        raise RuntimeError("Unaccepted release candidate")
    version = VERSION
    code = VERSION_CODE
    expected = {
        f"telltale-v{version}.aab",
        *(
            f"telltale-v{version}-{abi}.apk"
            for abi in ("armeabi-v7a", "arm64-v8a", "x86_64")
        ),
    }
    if {asset.get("file") for asset in candidate["assets"]} != expected or len(
        candidate["assets"]
    ) != 4:
        raise RuntimeError("Unexpected candidate files")
    if args.output.exists():
        raise RuntimeError("Refusing to replace existing release output")

    # Fully parse untrusted artifacts with secret-free pinned tools first.
    for asset in candidate["assets"]:
        validate_candidate_asset(
            args.candidate / asset["file"], asset, toolchain, version, code
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    secrets = {
        "TELLTALE_STORE_PASSWORD": signing["storePassword"],
        "TELLTALE_KEY_PASSWORD": signing["keyPassword"],
    }
    env = clean_environment(secrets)
    with (
        tempfile.TemporaryDirectory(prefix="telltale-signing-") as secret_name,
        tempfile.TemporaryDirectory(
            prefix=".telltale-staging-", dir=args.output.parent
        ) as staging_name,
    ):
        secret = Path(secret_name)
        secret.chmod(0o700)
        key = secret / "upload.jks"
        try:
            key.write_bytes(base64.b64decode(signing["keystoreBase64"], validate=True))
        except (ValueError, binascii.Error) as error:
            raise RuntimeError("Invalid keystore encoding") from error
        key.chmod(0o600)
        check = subprocess.check_output(
            [
                str(toolchain.keytool),
                "-list",
                "-v",
                "-keystore",
                str(key),
                "-alias",
                signing["keyAlias"],
                "-storepass:env",
                "TELLTALE_STORE_PASSWORD",
            ],
            text=True,
            env=env,
        )
        certificate(check, r"SHA256:\s*([A-Fa-f0-9:]+)")
        staging = Path(staging_name)
        assets: list[dict[str, Any]] = []
        for asset in candidate["assets"]:
            name = asset["file"]
            src = args.candidate / name
            validate_candidate_asset(src, asset, toolchain, version, code)
            target = staging / name
            if src.suffix == ".aab":
                command = [
                    str(toolchain.jarsigner),
                    "-keystore",
                    str(key),
                    "-storepass:env",
                    "TELLTALE_STORE_PASSWORD",
                    "-keypass:env",
                    "TELLTALE_KEY_PASSWORD",
                    "-signedjar",
                    str(target),
                    str(src),
                    signing["keyAlias"],
                ]
            else:
                aligned = secret / name
                subprocess.run(
                    [
                        str(toolchain.zipalign),
                        "-P",
                        "16",
                        "-f",
                        "4",
                        str(src),
                        str(aligned),
                    ],
                    capture_output=True,
                    env=toolchain.environment,
                    check=True,
                )
                command = [
                    str(toolchain.apksigner),
                    "sign",
                    "--ks",
                    str(key),
                    "--ks-key-alias",
                    signing["keyAlias"],
                    "--ks-pass",
                    "env:TELLTALE_STORE_PASSWORD",
                    "--key-pass",
                    "env:TELLTALE_KEY_PASSWORD",
                    "--out",
                    str(target),
                    str(aligned),
                ]
            subprocess.run(command, capture_output=True, env=env, check=True)
            verify_artifact(
                target, toolchain, version, code, env, key, signing["keyAlias"]
            )
            assets.append(
                {
                    "file": name,
                    "bytes": target.stat().st_size,
                    "sha256": sha256(target),
                    "unsignedSha256": asset["sha256"],
                }
            )
        receipt = {
            "status": "PASS",
            "executionMode": "9700x-private-ssh-signing",
            "sourceCommit": args.source,
            "sourceTree": candidate["sourceTree"],
            "acceptedGateJob": gate["id"],
            "acceptedGateRunnerId": RUNNER_ID,
            "candidateBuildJob": gate["id"],
            "candidateBuildRunnerId": RUNNER_ID,
            "candidateImage": IMAGE,
            "toolchainReceiptSha256": TOOLCHAIN_RECEIPT_SHA256,
            "androidAutoManifestContract": "PASS",
            "signerCertificateSha256": MAINTAINER_CERT,
            "versionName": version,
            "bundleVersionCode": code,
            "assets": assets,
        }
        (staging / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        (staging / "SHA256SUMS").write_text(
            "".join(asset["sha256"] + "  " + asset["file"] + "\n" for asset in assets)
        )
        staging.rename(args.output)
    print("Signed unified AAB and three APKs verified on the 9700X")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("candidate", "gate", "output", "tools", "toolchain-receipt"):
        parser.add_argument("--" + name, required=True, type=Path)
    parser.add_argument("--source", required=True)
    args = parser.parse_args()
    toolchain = validate_toolchain(args.toolchain_receipt, args.tools)
    signing = json.load(sys.stdin)
    sign(args, signing, toolchain)


if __name__ == "__main__":
    main()

import importlib.util
import os
import re
from pathlib import Path
import sys
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "signed_release", ROOT / "tool/ci/build_signed_release.py"
)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def aab_manifest(category=MODULE.CAR_CATEGORY, resource=MODULE.CAR_METADATA_RESOURCE):
    return f'''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="{MODULE.PACKAGE}" android:versionName="{MODULE.VERSION}"
        android:versionCode="{MODULE.VERSION_CODE}">
      <application>
        <meta-data android:name="{MODULE.CAR_METADATA}" android:resource="{resource}" />
        <service android:name="{MODULE.CAR_SERVICE}" android:exported="true">
          <intent-filter>
            <action android:name="{MODULE.CAR_ACTION}" />
            <category android:name="{category}" />
          </intent-filter>
        </service>
      </application>
    </manifest>'''


def apk_xmltree(
    action=MODULE.CAR_ACTION, category=MODULE.CAR_CATEGORY, resource="@0x7f120001"
):
    return f'''E: manifest (line=2)
  E: application (line=10)
    E: meta-data (line=11)
      A: android:name(0x01010003)="{MODULE.CAR_METADATA}" (Raw: "{MODULE.CAR_METADATA}")
      A: android:resource(0x01010025)={resource}
    E: service (line=15)
      A: android:name(0x01010003)="{MODULE.CAR_SERVICE}" (Raw: "{MODULE.CAR_SERVICE}")
      A: android:exported(0x01010010)=(type 0x12)0xffffffff
      E: intent-filter (line=17)
        E: action (line=18)
          A: android:name(0x01010003)="{action}" (Raw: "{action}")
        E: category (line=19)
          A: android:name(0x01010003)="{category}" (Raw: "{category}")'''


RESOURCES = f"spec resource 0x7f120001 {MODULE.PACKAGE}:xml/automotive_app_desc: flags=0x00000000"


class SignedReleaseBindingTest(unittest.TestCase):
    def job(self):
        return {
            "status": "success",
            "name": "full-gate",
            "ref": "main",
            "tag": False,
            "commit": {"id": "a" * 40},
            "pipeline": {
                "project_id": 86385809,
                "sha": "a" * 40,
                "ref": "main",
                "status": "success",
                "source": "push",
            },
            "runner": {"id": 57287642},
        }

    def test_exact_source_and_selected_remote_runner_pass(self):
        MODULE.validate_gate(self.job(), "a" * 40)

    def test_unrelated_pass_or_other_runner_cannot_authorize_signing(self):
        for key, value in [
            ("status", "running"),
            ("name", "full-gate-mr"),
            ("ref", "feature"),
            ("tag", True),
            ("commit", {"id": "b" * 40}),
            ("pipeline", {"project_id": 1}),
            ("runner", {"id": 1}),
        ]:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                job = self.job()
                job[key] = value
                MODULE.validate_gate(job, "a" * 40)

    def test_candidate_requires_api_dispatch(self):
        job = self.job()
        with self.assertRaises(RuntimeError):
            MODULE.validate_candidate_job(job, "a" * 40)
        job["pipeline"]["source"] = "api"
        MODULE.validate_candidate_job(job, "a" * 40)

    def test_environment_is_minimal_and_drops_injection_controls(self):
        injected = {
            "LD_PRELOAD": "/tmp/evil.so",
            "LD_LIBRARY_PATH": "/tmp",
            "JAVA_TOOL_OPTIONS": "-javaagent:evil.jar",
            "_JAVA_OPTIONS": "-Xbootclasspath/a:evil.jar",
            "JDK_JAVA_OPTIONS": "-javaagent:evil.jar",
            "CLASSPATH": "/tmp/evil.jar",
        }
        with mock.patch.dict(os.environ, injected, clear=False):
            env = MODULE.clean_environment()
        self.assertTrue(set(injected).isdisjoint(env))
        self.assertEqual(env["JAVA_HOME"], str(MODULE.JAVA_HOME))
        self.assertTrue(env["PATH"].startswith(str(MODULE.JAVA_HOME / "bin")))
        with self.assertRaises(RuntimeError):
            MODULE.clean_environment({"PATH": "/tmp"})

    def test_pinned_release_version_matches_pubspec(self):
        pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        match = re.search(r"^version:\s*(\S+)\+(\d+)\s*$", pubspec, re.M)
        self.assertIsNotNone(match)
        self.assertEqual(MODULE.VERSION, match.group(1))
        self.assertEqual(MODULE.VERSION_CODE, int(match.group(2)))

    def test_aab_manifest_requires_exact_android_auto_contract(self):
        MODULE.validate_aab_manifest(
            aab_manifest(), MODULE.VERSION, MODULE.VERSION_CODE
        )
        for xml in [
            aab_manifest(category="androidx.car.app.category.POI"),
            aab_manifest(resource="@xml/wrong"),
            aab_manifest().replace(
                f'android:versionCode="{MODULE.VERSION_CODE}"',
                f'android:versionCode="{MODULE.VERSION_CODE + 1}"',
            ),
        ]:
            with self.subTest(xml=xml), self.assertRaises(RuntimeError):
                MODULE.validate_aab_manifest(xml, MODULE.VERSION, MODULE.VERSION_CODE)

    def test_apk_manifest_requires_exact_android_auto_contract(self):
        MODULE.validate_apk_manifest(apk_xmltree(), RESOURCES)
        for tree, resources in [
            (apk_xmltree(action="wrong.action"), RESOURCES),
            (apk_xmltree(category="androidx.car.app.category.POI"), RESOURCES),
            (apk_xmltree(resource="@0x7f120002"), RESOURCES),
        ]:
            with self.subTest(tree=tree), self.assertRaises(RuntimeError):
                MODULE.validate_apk_manifest(tree, resources)

    def test_split_apk_version_codes_are_exact(self):
        expected = {"armeabi-v7a": 2001, "arm64-v8a": 2002, "x86_64": 2003}
        for abi, code in expected.items():
            self.assertEqual(
                MODULE.expected_apk_code(
                    f"telltale-v{MODULE.VERSION}-{abi}.apk", MODULE.VERSION, 200
                ),
                code,
            )
        with self.assertRaises(RuntimeError):
            MODULE.expected_apk_code(
                f"telltale-v{MODULE.VERSION}-universal.apk", MODULE.VERSION, 200
            )

    def test_aab_verification_uses_strict_input_keystore_trust_anchor(self):
        toolchain = MODULE.Toolchain(
            java=Path("/trusted/java"),
            keytool=Path("/trusted/keytool"),
            jarsigner=Path("/trusted/jarsigner"),
            aapt=Path("/trusted/aapt"),
            apksigner=Path("/trusted/apksigner"),
            zipalign=Path("/trusted/zipalign"),
            bundletool=Path("/trusted/bundletool.jar"),
            environment={},
        )
        command = MODULE.jarsigner_verify_command(
            toolchain, Path("release.aab"), Path("upload.jks"), "release-key"
        )
        self.assertEqual(
            command[:4], ["/trusted/jarsigner", "-verify", "-strict", "-keystore"]
        )
        self.assertIn("upload.jks", command)
        self.assertIn("-storepass:env", command)
        self.assertIn("TELLTALE_STORE_PASSWORD", command)
        self.assertEqual(command[-2:], ["release.aab", "release-key"])

    def test_signing_payload_rejects_extra_fields_bad_alias_and_nul(self):
        valid = {
            "keystoreBase64": "YWJj",
            "storePassword": "store",
            "keyPassword": "key",
            "keyAlias": "release-key",
        }
        self.assertEqual(MODULE.validate_signing(valid), valid)
        for change in [
            {**valid, "extra": "x"},
            {**valid, "keyAlias": "bad alias"},
            {**valid, "storePassword": "bad\0password"},
        ]:
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                MODULE.validate_signing(change)

    def test_output_signer_must_be_expected_and_unique(self):
        pattern = r"SHA256:\s*([A-Fa-f0-9:]+)"
        self.assertEqual(
            MODULE.certificate("SHA256: " + MODULE.MAINTAINER_CERT, pattern),
            MODULE.MAINTAINER_CERT,
        )
        for output in [
            "SHA256: " + ("a" * 64),
            "no certificate",
            "SHA256: " + MODULE.MAINTAINER_CERT + "\nSHA256: " + MODULE.MAINTAINER_CERT,
        ]:
            with self.subTest(output=output), self.assertRaises(RuntimeError):
                MODULE.certificate(output, pattern)


if __name__ == "__main__":
    unittest.main()

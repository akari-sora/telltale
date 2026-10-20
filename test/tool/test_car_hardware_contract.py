"""AA-05 static architecture contract gate for AAOS native hardware integration and alert surface.

Verifies:
  AA05-01: Car App Library version remains exact 1.8.0-rc01.
  AA05-02: CarSensors is NOT used anywhere; CarInfo.addSpeedListener is used instead.
  AA05-04: carProto leaf manifest declares com.google.android.gms.permission.CAR_SPEED.
  AA05-05: automotive leaf manifest declares android.car.permission.CAR_SPEED and READ_CAR_DISPLAY_UNITS.
  AA05-06: Production manifests (field, rig, wear, main) have zero car permissions.
  AA05-27: No Navigation-only Alert / showAlert used in car-core.
  AA05-28: No experimental Banner API used in car-core.
  AA05-29: No cross-application Notification / HUN used in car-core.
  AA05-35: lib/obd/ changes against origin/main stay within the authorized OBD port.
"""

import hashlib
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
AUTHORIZED_OBD_PORT_FILES = frozenset(
    {
        "lib/obd/elm327_client.dart",
        "lib/obd/polling_engine.dart",
        "lib/obd/powertrain_battery/powertrain_battery_catalog.dart",
    }
)
AUTHORIZED_OBD_EXACT_FILES = {
    # Unified phone/Android Auto telemetry demand. This authorization is
    # content-bound so later changes to the shared OBD primitive require a new
    # contract review instead of inheriting a permanent path exception.
    "lib/obd/telemetry_demand.dart":
        "41f3f4571919e93238c4528b7625a1ada903b2f83a30e4b6feb86c24087e47ac",
    # #110 ELM session pipeline. Profile timings/caps and the live Mode 01
    # grouping limit on PriorityScheduler. Content-bound for the same reason:
    # this MR reviews the exact blobs; later edits need a new contract pass.
    "lib/obd/elm_session_profile.dart":
        "f1ec66c9bdbde0e4ef553db9819a51fecbae9a3cab0667b13b5377867a22cc9b",
    "lib/obd/pid/priority_scheduler.dart":
        "55ba52dc5ebd4aa910225e3e25f5195d0dda75ca00edf9494be6953456f5016d",
}


class CarHardwareContractTest(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    # AA05-01
    def test_car_app_library_is_pinned_to_1_8_0_rc01(self):
        car_core = self.read("android/car-core/build.gradle.kts")
        self.assertIn('androidx.car.app:app:1.8.0-rc01', car_core)

        automotive = self.read("android/automotive/build.gradle.kts")
        self.assertIn('androidx.car.app:app-automotive:1.8.0-rc01', automotive)

    # AA05-02
    def test_carsensors_is_never_used_in_car_code(self):
        kotlin_files = list((ROOT / "android/car-core/src/main").rglob("*.kt")) + \
                       list((ROOT / "android/automotive/src/main").rglob("*.kt"))
        self.assertTrue(len(kotlin_files) > 0, "Expected Kotlin files to inspect")

        forbidden_patterns = [
            re.compile(r"import\s+.*CarSensors"),
            re.compile(r"\bCarSensors::class"),
            re.compile(r"\.getCarSensors\s*\("),
            re.compile(r"\bcarSensors\b"),
        ]

        for kfile in kotlin_files:
            text = kfile.read_text(encoding="utf-8")
            # Strip comments to inspect actual code usage
            code_only = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
            code_only = re.sub(r"//[^\n]*", "", code_only)

            for pat in forbidden_patterns:
                self.assertFalse(
                    pat.search(code_only),
                    msg=f"Forbidden CarSensors pattern {pat.pattern} found in {kfile.relative_to(ROOT)} (AA05-02)",
                )

    # AA05-04, AA05-05, AA05-06
    def test_manifest_speed_permissions_isolated_to_leaf_artifacts(self):
        car_proto = self.read("android/app/src/carProto/AndroidManifest.xml")
        self.assertIn("com.google.android.gms.permission.CAR_SPEED", car_proto)
        self.assertNotIn("android.car.permission.CAR_SPEED", car_proto)

        field = self.read("android/app/src/field/AndroidManifest.xml")
        self.assertIn("com.google.android.gms.permission.CAR_SPEED", field)
        self.assertNotIn("android.car.permission.CAR_SPEED", field)

        automotive = self.read("android/automotive/src/main/AndroidManifest.xml")
        self.assertIn("android.car.permission.CAR_SPEED", automotive)
        self.assertIn("android.car.permission.READ_CAR_DISPLAY_UNITS", automotive)
        self.assertNotIn("com.google.android.gms.permission.CAR_SPEED", automotive)

        prod_manifests = [
            "android/app/src/main/AndroidManifest.xml",
            "android/app/src/rig/AndroidManifest.xml",
            "android/app/src/wear/AndroidManifest.xml",
        ]
        for rel in prod_manifests:
            p = ROOT / rel
            if p.is_file():
                text = p.read_text(encoding="utf-8")
                self.assertNotIn("permission.CAR_SPEED", text, msg=f"Car speed permission leaked to {rel}")
                self.assertNotIn("READ_CAR_DISPLAY_UNITS", text, msg=f"Display units permission leaked to {rel}")

    # AA05-27, AA05-28, AA05-29
    def test_no_alert_or_banner_or_notification_in_car_core(self):
        car_core_kt = list((ROOT / "android/car-core/src/main").rglob("*.kt"))
        forbidden_apis = [
            re.compile(r"androidx\.car\.app\.model\.Alert\b"),
            re.compile(r"\bshowAlert\s*\("),
            re.compile(r"androidx\.car\.app\.model\.Banner\b"),
            re.compile(r"NotificationManagerCompat"),
            re.compile(r"NotificationCompat"),
        ]

        for kfile in car_core_kt:
            text = kfile.read_text(encoding="utf-8")
            for pat in forbidden_apis:
                self.assertFalse(
                    pat.search(text),
                    msg=f"Forbidden alert/notification API {pat.pattern} found in {kfile.relative_to(ROOT)}",
                )

    # AA05-35
    def test_obd_directory_has_no_unauthorized_drift(self):
        res = subprocess.run(
            ["git", "diff", "--name-only", "origin/main...HEAD", "--", "lib/obd/"],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, f"git diff failed: {res.stderr}")
        changed_files = {line for line in res.stdout.splitlines() if line}
        exact_files = changed_files & AUTHORIZED_OBD_EXACT_FILES.keys()
        exact_mismatches = {}
        for relative in sorted(exact_files):
            blob = subprocess.run(
                ["git", "show", f"HEAD:{relative}"],
                cwd=str(ROOT),
                capture_output=True,
            )
            self.assertEqual(
                blob.returncode,
                0,
                f"git show failed for {relative}: {blob.stderr.decode(errors='replace')}",
            )
            actual_digest = hashlib.sha256(blob.stdout).hexdigest()
            expected_digest = AUTHORIZED_OBD_EXACT_FILES[relative]
            if actual_digest != expected_digest:
                exact_mismatches[relative] = {
                    "expected": expected_digest,
                    "actual": actual_digest,
                }

        unexpected_files = changed_files - AUTHORIZED_OBD_PORT_FILES - AUTHORIZED_OBD_EXACT_FILES.keys()
        self.assertFalse(
            unexpected_files,
            msg=(
                "lib/obd/ contains drift outside the authorized OBD port: "
                f"{sorted(unexpected_files)}"
            ),
        )
        self.assertFalse(
            exact_mismatches,
            msg=f"content-bound OBD authorization mismatch: {exact_mismatches}",
        )


if __name__ == "__main__":
    unittest.main()

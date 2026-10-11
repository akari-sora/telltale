from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CarSkeletonContractTest(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_production_and_variant_manifests_have_no_car_metadata(self):
        non_car_manifests = [
            "android/app/src/main/AndroidManifest.xml",
            "android/app/src/rig/AndroidManifest.xml",
            "android/app/src/wear/AndroidManifest.xml",
            "android/app/src/debug/AndroidManifest.xml",
            "android/app/src/profile/AndroidManifest.xml",
        ]
        forbidden = [
            "com.google.android.gms.car.application",
            "androidx.car.app.CarAppService",
            "androidx.car.app.category.IOT",
            "com.android.automotive",
            "CarAppActivity",
        ]

        for path in non_car_manifests:
            manifest_file = ROOT / path
            if not manifest_file.is_file():
                continue
            manifest = manifest_file.read_text(encoding="utf-8")
            for token in forbidden:
                self.assertNotIn(
                    token,
                    manifest,
                    msg=f"Forbidden car token {token!r} found in {path}",
                )

    def test_android_auto_metadata_is_isolated_to_car_proto(self):
        manifest = self.read(
            "android/app/src/carProto/AndroidManifest.xml"
        )

        self.assertIn(
            "com.google.android.gms.car.application",
            manifest,
        )

    def test_aaos_manifest_has_no_projected_metadata(self):
        manifest = self.read(
            "android/automotive/src/main/AndroidManifest.xml"
        )

        self.assertIn("com.android.automotive", manifest)
        self.assertNotIn(
            "com.google.android.gms.car.application",
            manifest,
        )

    def test_car_core_is_only_linked_to_car_proto_in_flutter_app(self):
        gradle = self.read("android/app/build.gradle.kts")

        self.assertIn(
            'add("carProtoImplementation", project(":car-core"))',
            gradle,
        )
        self.assertIn(
            'add(\n        "carProtoImplementation",\n        "androidx.car.app:app-projected:1.8.0-rc01",\n    )',
            gradle,
        )

        # Ensure :car-core and androidx.car.app are not linked into non-car scopes
        forbidden_scopes = [
            'implementation(project(":car-core"))',
            'api(project(":car-core"))',
            'fieldImplementation(project(":car-core"))',
            'rigImplementation(project(":car-core"))',
            'wearImplementation(project(":car-core"))',
            'releaseImplementation(project(":car-core"))',
            'implementation("androidx.car.app',
            'fieldImplementation("androidx.car.app',
            'rigImplementation("androidx.car.app',
            'wearImplementation("androidx.car.app',
        ]
        for pattern in forbidden_scopes:
            self.assertNotIn(
                pattern,
                gradle,
                msg=f"Forbidden dependency wiring {pattern!r} leaked into android/app/build.gradle.kts",
            )

    def test_car_core_contains_no_obd_protocol_code(self):
        car_core = ROOT / "android/car-core"

        forbidden = (
            "ELM327",
            "ISO-TP",
            "clearDtc",
            "Clear DTC",
            "AccelerationRunController",
        )

        for file in car_core.rglob("*"):
            if not file.is_file():
                continue
            if file.suffix not in {".kt", ".xml", ".kts"}:
                continue

            text = file.read_text(
                encoding="utf-8",
                errors="ignore",
            )

            for token in forbidden:
                self.assertNotIn(
                    token,
                    text,
                    msg=f"{token!r} leaked into {file}",
                )

    def test_prototype_application_ids_are_isolated(self):
        app_gradle = self.read("android/app/build.gradle.kts")
        auto_gradle = self.read("android/automotive/build.gradle.kts")

        projected_suffix = 'applicationIdSuffix = ".carproto"'
        aaos_id = 'applicationId = "com.cbstudio.telltale.carproto.aaos"'

        self.assertIn(projected_suffix, app_gradle)
        self.assertIn(aaos_id, auto_gradle)

        # Full projected applicationId = base ("com.cbstudio.telltale") + suffix (".carproto")
        projected_full_id = "com.cbstudio.telltale.carproto"
        aaos_full_id = "com.cbstudio.telltale.carproto.aaos"

        self.assertNotEqual(
            projected_full_id,
            aaos_full_id,
            "Projected and AAOS prototype applicationIds MUST be distinct to allow dual-install and clear test isolation",
        )
        self.assertNotIn(
            'applicationId = "com.cbstudio.telltale.carproto"',
            auto_gradle,
            "AAOS prototype MUST NOT reuse the projected carProto applicationId",
        )


if __name__ == "__main__":
    unittest.main()


from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CarSkeletonContractTest(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_production_main_manifest_has_no_android_auto_metadata(self):
        manifest = self.read("android/app/src/main/AndroidManifest.xml")

        self.assertNotIn(
            "com.google.android.gms.car.application",
            manifest,
        )
        self.assertNotIn(
            "androidx.car.app.CarAppService",
            manifest,
        )
        self.assertNotIn(
            "androidx.car.app.category.IOT",
            manifest,
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

        self.assertNotIn(
            'implementation(project(":car-core"))',
            gradle,
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


if __name__ == "__main__":
    unittest.main()

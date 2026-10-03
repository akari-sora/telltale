from pathlib import Path
import tempfile
import unittest

from tool.ci.verify_car_manifest_isolation import verify_manifest


class VerifyCarManifestIsolationTest(unittest.TestCase):
    def test_car_proto_contract_fixture(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest = Path(tmpdir) / "AndroidManifest.xml"
            manifest.write_text(
                """<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data android:name="com.google.android.gms.car.application" android:resource="@xml/desc"/>
        <service android:name="androidx.car.app.CarAppService">
            <intent-filter>
                <category android:name="androidx.car.app.category.IOT"/>
            </intent-filter>
        </service>
    </application>
</manifest>""",
                encoding="utf-8",
            )
            errors = verify_manifest(
                name="carProto test",
                path=manifest,
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
            self.assertEqual(errors, [])

    def test_field_production_contract_fixture(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest = Path(tmpdir) / "AndroidManifest.xml"
            manifest.write_text(
                """<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <activity android:name=".MainActivity"/>
    </application>
</manifest>""",
                encoding="utf-8",
            )
            errors = verify_manifest(
                name="field test",
                path=manifest,
                must_contain=[],
                must_not_contain=[
                    "CarAppService",
                    "category.IOT",
                    "com.google.android.gms.car.application",
                    "com.android.automotive",
                    "CarAppActivity",
                ],
            )
            self.assertEqual(errors, [])

    def test_automotive_contract_fixture(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest = Path(tmpdir) / "AndroidManifest.xml"
            manifest.write_text(
                """<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.type.automotive" android:required="true"/>
    <application>
        <meta-data android:name="com.android.automotive" android:resource="@xml/desc"/>
        <activity android:name="androidx.car.app.activity.CarAppActivity"/>
        <service android:name="androidx.car.app.CarAppService"/>
    </application>
</manifest>""",
                encoding="utf-8",
            )
            errors = verify_manifest(
                name="automotive test",
                path=manifest,
                must_contain=[
                    "CarAppService",
                    "com.android.automotive",
                    "CarAppActivity",
                ],
                must_not_contain=[
                    "com.google.android.gms.car.application",
                ],
            )
            self.assertEqual(errors, [])

    def test_detects_forbidden_leak(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest = Path(tmpdir) / "AndroidManifest.xml"
            manifest.write_text(
                """<manifest>
    <application>
        <service android:name="androidx.car.app.CarAppService"/>
    </application>
</manifest>""",
                encoding="utf-8",
            )
            errors = verify_manifest(
                name="leak test",
                path=manifest,
                must_contain=[],
                must_not_contain=["CarAppService"],
            )
            self.assertEqual(len(errors), 1)
            self.assertIn("CarAppService", errors[0])


if __name__ == "__main__":
    unittest.main()

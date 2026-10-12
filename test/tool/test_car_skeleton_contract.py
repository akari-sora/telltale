from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]


class CarSkeletonContractTest(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_non_projection_manifests_have_no_car_metadata(self):
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
            "ProjectionForegroundService",
            "FOREGROUND_SERVICE_CONNECTED_DEVICE",
            "android.permission.WAKE_LOCK",
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

    def test_android_auto_metadata_is_in_field_and_car_proto(self):
        for flavor in ("field", "carProto"):
            manifest = self.read(f"android/app/src/{flavor}/AndroidManifest.xml")
            self.assertIn('android:name=".ProjectedTelltaleApplication"', manifest)
            self.assertIn('xmlns:tools="http://schemas.android.com/tools"', manifest)
            self.assertIn('tools:replace="android:name"', manifest)
            self.assertIn("com.google.android.gms.car.application", manifest)
            self.assertIn("ProjectionForegroundService", manifest)
            self.assertIn('android:foregroundServiceType="connectedDevice"', manifest)
            self.assertIn("android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE", manifest)
            self.assertIn("android.permission.WAKE_LOCK", manifest)

    def test_projection_service_is_non_sticky_and_releases_its_wake_lock(self):
        service = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionForegroundService.kt"
        )
        on_destroy = service[
            service.index("override fun onDestroy()"):
            service.index("override fun onBind")
        ]

        self.assertIn("return START_NOT_STICKY", service)
        self.assertIn("PowerManager.PARTIAL_WAKE_LOCK", service)
        self.assertIn("wakeLock?.takeIf { it.isHeld }?.release()", service)
        self.assertIn("releaseWakeLock()", on_destroy)
        self.assertIn("ProjectionContinuityRuntime.markServiceStopped", on_destroy)
        self.assertLess(
            on_destroy.index("releaseWakeLock()"),
            on_destroy.index("ProjectionContinuityRuntime.markServiceStopped"),
        )
        self.assertLess(
            on_destroy.index("ProjectionContinuityRuntime.markServiceStopped"),
            on_destroy.index("super.onDestroy()"),
        )

    def test_projection_service_notification_copy_is_localized(self):
        service = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionForegroundService.kt"
        )
        expected = {
            "projection_notification_channel_name",
            "projection_notification_title",
            "projection_notification_live_body",
            "projection_notification_waiting_body",
        }

        for resource in expected:
            self.assertIn(f"R.string.{resource}", service)

        for hardcoded in (
            '"OBD adapter connection"',
            '"Telltale OBD adapter connected"',
            '"Live vehicle telemetry is continuing for Android Auto"',
            '"Waiting for Android Auto"',
        ):
            self.assertNotIn(hardcoded, service)

        for values_dir in ("values", "values-zh-rTW"):
            path = (
                ROOT
                / "android/app/src/carProto/res"
                / values_dir
                / "strings.xml"
            )
            strings = {
                node.attrib["name"]: node.text
                for node in ET.parse(path).getroot().findall("string")
            }
            self.assertEqual(expected, strings.keys())
            self.assertTrue(all(value and value.strip() for value in strings.values()))

    def test_projection_service_claim_and_retirement_are_generation_scoped(self):
        service = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionForegroundService.kt"
        )
        runtime = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionContinuityRuntime.kt"
        )
        on_start = service[
            service.index("override fun onStartCommand"):
            service.index("override fun onDestroy()")
        ]
        stop_producer = service[
            service.index("private fun stopProducer"):
            service.index("private fun startInForeground")
        ]
        claim_producer = runtime[
            runtime.index("override fun claimProducerConnection"):
            runtime.index("override fun retireProducerConnection")
        ]

        self.assertIn("intent?.action == ACTION_CLAIM_PRODUCER", on_start)
        self.assertIn(
            "ProjectionContinuityRuntime.markServiceProducerConfirmed(requestedConnectionGeneration)",
            on_start,
        )
        self.assertIn("connectionGeneration = priorConnectionGeneration", on_start)
        self.assertIn(
            "if (!ProjectionContinuityRuntime.hasProducerOwnerOrPendingClaim())",
            on_start,
        )
        self.assertIn(
            "if (this.connectionGeneration != connectionGeneration) return false",
            stop_producer,
        )
        self.assertLess(
            stop_producer.index("setProjectionArmed(armed = false)"),
            stop_producer.index("stopSelfResult(latestStartId)"),
        )

        self.assertIn("state.canClaimProducer(", claim_producer)
        self.assertIn("producerStartAuthorized = activityResumed ||", claim_producer)
        self.assertIn("(carServiceActive && state.projectionActive)", claim_producer)
        self.assertIn("hasEngine = engineOwner.current() != null", claim_producer)
        self.assertEqual(claim_producer.count("startForegroundService("), 1)
        self.assertLess(
            claim_producer.index("state.beginProducerClaim(connectionGeneration)"),
            claim_producer.index("startForegroundService("),
        )
        self.assertIn("state.cancelProducerClaim(connectionGeneration)", claim_producer)
        self.assertEqual(runtime.count("startForegroundService("), 1)
        self.assertNotIn("stopService(", runtime)
        self.assertIn(
            "ProjectionForegroundService.stopProducer(connectionGeneration)",
            runtime,
        )

    def test_car_service_bootstraps_projected_process_before_session(self):
        service = self.read(
            "android/car-core/src/main/kotlin/com/cbstudio/telltale/car/"
            "TelltaleCarAppService.kt"
        )
        application = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectedTelltaleApplication.kt"
        )
        runtime = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionContinuityRuntime.kt"
        )

        self.assertIn("(application as? CarProcessBootstrap)?.ensureCarRuntimeStarted()", service)
        self.assertIn("(application as? CarProcessBootstrap)?.releaseCarRuntimeIfIdle()", service)
        self.assertIn("class ProjectedTelltaleApplication", application)
        self.assertIn("ProjectionContinuityRuntime.onCarServiceStarted(this)", application)
        self.assertIn("FlutterEngine(context.applicationContext)", runtime)
        self.assertIn("executeDartEntrypoint", runtime)
        self.assertIn("fun retainedEngine(): FlutterEngine? = engineOwner.current()", runtime)
        self.assertIn("fun ownsEngine(candidate: FlutterEngine)", runtime)

        main_activity = self.read(
            "android/app/src/main/kotlin/com/cbstudio/telltale/MainActivity.kt"
        )
        self.assertIn("if (!FlavorPlatformRegistrar.ownsProcessEngine(flutterEngine))", main_activity)

        for flavor in ("rig", "wear"):
            registrar = self.read(
                f"android/app/src/{flavor}/kotlin/com/cbstudio/telltale/"
                "FlavorPlatformRegistrar.kt"
            )
            self.assertNotIn("ProjectedTelltaleApplication", registrar)

    def test_aaos_manifest_has_no_projected_metadata(self):
        manifest = self.read(
            "android/automotive/src/main/AndroidManifest.xml"
        )

        self.assertIn("com.android.automotive", manifest)
        self.assertNotIn(
            "com.google.android.gms.car.application",
            manifest,
        )
        self.assertNotIn("ProjectionForegroundService", manifest)
        self.assertNotIn("FOREGROUND_SERVICE_CONNECTED_DEVICE", manifest)

    def test_car_core_is_linked_to_both_projection_flavors(self):
        gradle = self.read("android/app/build.gradle.kts")

        self.assertIn('listOf("field", "carProto").forEach { flavor ->', gradle)
        self.assertIn('add("${flavor}Implementation", project(":car-core"))', gradle)
        self.assertIn('"androidx.car.app:app-projected:1.8.0-rc01"', gradle)
        self.assertIn('sourceSets.getByName("field").java.srcDir("src/carProto/kotlin")', gradle)
        self.assertIn('sourceSets.getByName("field").res.srcDir("src/carProto/res")', gradle)

        # Ensure :car-core and androidx.car.app are not linked into non-projection scopes.
        forbidden_scopes = [
            'implementation(project(":car-core"))',
            'api(project(":car-core"))',
            'rigImplementation(project(":car-core"))',
            'wearImplementation(project(":car-core"))',
            'releaseImplementation(project(":car-core"))',
            'implementation("androidx.car.app',
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

    def test_unsigned_release_override_never_falls_back_to_debug_signing(self):
        gradle = self.read("android/app/build.gradle.kts")
        release_block = gradle[
            gradle.index("buildTypes {"):
            gradle.index("// Release artifacts must be release-signed")
        ]

        self.assertIn('signingConfig = signingConfigs.getByName("release")', release_block)
        self.assertIn("signingConfig = null", release_block)
        self.assertNotIn('signingConfigs.getByName("debug")', release_block)
        self.assertIn("allowUnsignedRelease", gradle)
        self.assertIn("if (requested.isNotEmpty() && !optedOut)", gradle)


if __name__ == "__main__":
    unittest.main()


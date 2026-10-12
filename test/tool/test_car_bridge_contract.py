"""AA-02 static architecture gate for the one-way car telemetry bridge.

Complements the behavioural tests (test/car/**, :car-core and the projected
flavor unit lanes) with source-level invariants that a refactor
could otherwise break silently.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]

PIGEON_INPUT = "pigeons/car_telemetry.dart"
GENERATED_DART = "lib/car/generated/car_telemetry.g.dart"
GENERATED_KOTLIN = (
    "android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/"
    "generated/CarTelemetry.g.kt"
)
MAIN_ACTIVITY = "android/app/src/main/kotlin/com/cbstudio/telltale/MainActivity.kt"
NON_CAR_FLAVORS = ("rig", "wear")


def _strip_dart_comments(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    return re.sub(r"//[^\n]*", "", source)


class CarBridgeContractTest(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    # AA02-01
    def test_pigeon_is_exactly_pinned(self):
        pubspec = self.read("pubspec.yaml")
        self.assertRegex(pubspec, r"(?m)^  pigeon: 29\.0\.6\s*$")
        self.assertNotRegex(pubspec, r"(?m)^  pigeon: *[\^~>]")
        lock = self.read("pubspec.lock")
        self.assertRegex(
            lock,
            r'(?s)\n  pigeon:\n    dependency: "direct dev"\n.*?version: "29\.0\.6"',
        )

    # AA02-03
    def test_schema_declares_one_host_api_and_no_flutter_api(self):
        for path in ("pigeons/car_telemetry.dart", "pigeons/car_diagnostics.dart"):
            source = _strip_dart_comments(self.read(path))
            self.assertEqual(len(re.findall(r"@HostApi\s*\(", source)), 1, msg=f"HostApi count in {path}")
            self.assertEqual(re.findall(r"@FlutterApi\s*\(", source), [], msg=f"FlutterApi in {path}")
            self.assertEqual(re.findall(r"@EventChannelApi\s*\(", source), [], msg=f"EventChannelApi in {path}")
        self.assertIn("void publishTelemetryFrame(CarTelemetryMessage frame);", self.read("pigeons/car_telemetry.dart"))
        self.assertIn("void publishDtcReport(CarDtcReportMessage report);", self.read("pigeons/car_diagnostics.dart"))

        lifecycle = _strip_dart_comments(self.read("pigeons/car_projection_session.dart"))
        self.assertEqual(len(re.findall(r"@HostApi\s*\(", lifecycle)), 1)
        self.assertEqual(len(re.findall(r"@FlutterApi\s*\(", lifecycle)), 1)
        self.assertIn("armContinuity", lifecycle)
        self.assertIn("acknowledgeRelease", lifecycle)

    def test_generated_code_has_no_kotlin_to_dart_api(self):
        pairs = [
            (
                "android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/generated/CarTelemetry.g.kt",
                "lib/car/generated/car_telemetry.g.dart",
                "CarTelemetryHostApi",
            ),
            (
                "android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/generated/CarDiagnostics.g.kt",
                "lib/car/generated/car_diagnostics.g.dart",
                "CarDiagnosticsHostApi",
            ),
        ]
        for kt_path, dart_path, host_api in pairs:
            kotlin = self.read(kt_path)
            dart = self.read(dart_path)
            self.assertNotIn("class CarTelemetryFlutterApi", kotlin)
            self.assertNotIn("class CarDiagnosticsFlutterApi", kotlin)
            self.assertNotRegex(kotlin, r"class \w+FlutterApi\(")
            self.assertNotRegex(dart, r"abstract class \w+ \{\s*static const MessageCodec")
            self.assertEqual(len(re.findall(r"(?m)^interface \w+", kotlin)), 1)
            self.assertIn(f"interface {host_api}", kotlin)

    # AA02-04
    def test_schema_version_is_one_on_both_ends(self):
        dart = self.read("lib/car/car_telemetry_frame.dart")
        self.assertIn("const int carTelemetrySchemaVersion = 1;", dart)
        kotlin = self.read(
            "android/car-core/src/main/kotlin/com/cbstudio/telltale/car/"
            "telemetry/CarTelemetryFrame.kt"
        )
        self.assertIn("const val SCHEMA_VERSION: Long = 1", kotlin)

    # AA02-07
    def test_generated_kotlin_exists_only_in_car_proto(self):
        hits = sorted(
            str(p.relative_to(ROOT))
            for p in (ROOT / "android").rglob("*.kt")
            if "/build/" not in str(p)
            and any(api in p.read_text(encoding="utf-8") for api in ("CarTelemetryHostApi", "CarDiagnosticsHostApi"))
        )
        self.assertTrue(hits)
        for path in hits:
            self.assertTrue(
                path.startswith("android/app/src/carProto/")
                or path.startswith("android/app/src/testCarProto/"),
                msg=f"car bridge API referenced outside carProto: {path}",
            )

    # AA02-08
    def test_main_activity_only_calls_generic_registrar(self):
        source = self.read(MAIN_ACTIVITY)
        self.assertIn("FlavorPlatformRegistrar.register(flutterEngine)", source)
        for forbidden in (
            "CarTelemetryHostApi",
            "CarDiagnosticsHostApi",
            "carbridge",
            "com.cbstudio.telltale.car.",
            "CarTelemetryRuntime",
            "CarDtcRuntime",
            "Class.forName",
        ):
            self.assertNotIn(forbidden, source, msg=forbidden)

    def test_projected_flavors_share_registrar_and_non_car_ones_are_inert(self):
        car = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "FlavorPlatformRegistrar.kt"
        )
        self.assertIn("CarTelemetryHostApi.setUp(", car)
        gradle = self.read("android/app/build.gradle.kts")
        self.assertIn(
            'sourceSets.getByName("field").java.srcDir("src/carProto/kotlin")',
            gradle,
        )
        self.assertFalse(
            (ROOT / "android/app/src/field/kotlin/com/cbstudio/telltale/FlavorPlatformRegistrar.kt").exists()
        )
        for flavor in NON_CAR_FLAVORS:
            path = (
                f"android/app/src/{flavor}/kotlin/com/cbstudio/telltale/"
                "FlavorPlatformRegistrar.kt"
            )
            source = self.read(path)
            self.assertIn("internal object FlavorPlatformRegistrar", source)
            self.assertIn("fun register(flutterEngine: FlutterEngine) = Unit", source)
            for forbidden in ("carbridge", "com.cbstudio.telltale.car.", "CarTelemetry"):
                self.assertNotIn(forbidden, source, msg=f"{forbidden} in {path}")
            imports = re.findall(r"(?m)^import (\S+)", source)
            self.assertEqual(
                imports,
                ["android.content.Context", "io.flutter.embedding.engine.FlutterEngine"],
            )

    def test_non_car_source_sets_contain_no_car_code(self):
        for flavor in NON_CAR_FLAVORS + ("main",):
            base = ROOT / "android/app/src" / flavor
            for path in base.rglob("*.kt"):
                text = path.read_text(encoding="utf-8")
                for forbidden in ("import com.cbstudio.telltale.car", "carbridge"):
                    self.assertNotIn(
                        forbidden,
                        text,
                        msg=f"{forbidden} in {path.relative_to(ROOT)}",
                    )

    def test_car_core_is_only_in_projected_flavors(self):
        gradle = self.read("android/app/build.gradle.kts")
        deps = re.findall(r'project\(":car-core"\)', gradle)
        self.assertEqual(len(deps), 1)
        self.assertIn('listOf("field", "carProto").forEach { flavor ->', gradle)
        self.assertIn('add("${flavor}Implementation", project(":car-core"))', gradle)

    def test_obd_never_imports_car(self):
        for path in (ROOT / "lib/obd").rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            self.assertNotRegex(
                text,
                r"import\s+['\"](\.\./)+car/",
                msg=str(path.relative_to(ROOT)),
            )
            self.assertNotIn("package:torque_obd/car/", text, msg=str(path))

    def test_car_layer_calls_no_session_or_scan_mutation(self):
        mutation = re.compile(
            r"\.(connect|connectBle|connectWifi|connectDemo|disconnect|clear"
            r"|clearDtcs|scan|setActivePids|syncActivePids|probe\w*"
            r"|recordFieldEvent\w*|reset\w*|invalidate\w*)\s*\("
        )
        assignment = re.compile(r"\.state\s*=(?!=)")
        for path in (ROOT / "lib/car").rglob("*.dart"):
            if path.name.endswith(".g.dart"):
                continue
            text = _strip_dart_comments(path.read_text(encoding="utf-8"))
            rel = path.relative_to(ROOT)
            self.assertEqual(mutation.findall(text), [], msg=str(rel))
            self.assertEqual(assignment.findall(text), [], msg=str(rel))

    def test_mutation_detector_catches_real_calls(self):
        # Guards the guard: the regex above must flag the calls it names.
        mutation = re.compile(
            r"\.(connect|connectBle|connectWifi|connectDemo|disconnect|clear"
            r"|clearDtcs|scan|setActivePids|syncActivePids|probe\w*"
            r"|recordFieldEvent\w*|reset\w*|invalidate\w*)\s*\("
        )
        for call in (
            "session.disconnect()",
            "ref.read(dtcScanProvider.notifier).scan()",
            "n.clear()",
            "s.connectDemo()",
        ):
            self.assertTrue(mutation.search(call), msg=call)
        self.assertIsNone(mutation.search("ConnectionPhase.connected"))

    def test_runtime_is_gated_and_held_live(self):
        main = self.read("lib/main.dart")
        self.assertIn("carProjectionEnabledProvider.overrideWithValue(", main)
        self.assertIn("isCarProjectionEligible(platformMetadata)", main)
        app = self.read("lib/app.dart")
        # A bare ref.read leaves the provider paused (Riverpod 3), which would
        # also pause its telemetry listener.
        self.assertIn("ref.listenManual(carProjectionRuntimeProvider", app)
        self.assertNotIn("ref.read(carProjectionRuntimeProvider)", app)
        runtime = self.read("lib/car/car_projection_runtime.dart")
        self.assertIn(
            "const String androidCarProtoApplicationId = "
            "'com.cbstudio.telltale.carproto';",
            runtime,
        )
        self.assertIn("'field' => androidFieldApplicationId", runtime)
        self.assertIn("'carProto' => androidCarProtoApplicationId", runtime)
        self.assertIn("final carProjectionEnabledProvider = Provider<bool>((ref) => false);", runtime)

    def test_drift_gate_and_car_unit_lanes_are_in_full_gate(self):
        gate = self.read("tool/ci/full_gate.sh")
        self.assertIn("run_step car-pigeon-codegen bash tool/ci/verify_car_pigeon_codegen.sh", gate)
        self.assertIn(":car-core:testDebugUnitTest", gate)
        self.assertIn(":app:testFieldDebugUnitTest", gate)
        self.assertIn(":app:testCarProtoDebugUnitTest", gate)
        self.assertLess(gate.index("run_step pub-get"), gate.index("car-pigeon-codegen"))

    def test_forbidden_runtime_scope_is_absent(self):
        roots = [
            ROOT / "lib/car",
            ROOT / "android/car-core/src/main",
            ROOT / "android/app/src/carProto",
        ]
        forbidden = ("FlutterEngineCache", "CarUxRestrictions")
        for root in roots:
            for path in root.rglob("*"):
                if not path.is_file() or path.suffix not in {".kt", ".dart", ".xml"}:
                    continue
                text = _strip_dart_comments(path.read_text(encoding="utf-8"))
                text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
                for token in forbidden:
                    self.assertNotIn(token, text, msg=f"{token} in {path.relative_to(ROOT)}")

        service_path = (
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionForegroundService.kt"
        )
        runtime_path = (
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "ProjectionContinuityRuntime.kt"
        )
        platform_api_scopes = {
            "android.os.PowerManager": {service_path},
            "PowerManager.WakeLock": {service_path},
            "PowerManager.PARTIAL_WAKE_LOCK": {service_path},
            ".newWakeLock(": {service_path},
            "startForeground(": {service_path},
            "startForegroundService(": {runtime_path},
            "FOREGROUND_SERVICE": {
                "android/app/src/carProto/AndroidManifest.xml",
                service_path,
            },
        }
        for token, allowed_runtime in platform_api_scopes.items():
            hits = {
                str(path.relative_to(ROOT))
                for root in roots
                for path in root.rglob("*")
                if path.is_file()
                and path.suffix in {".kt", ".dart", ".xml"}
                and token in re.sub(r"<!--.*?-->", "", _strip_dart_comments(path.read_text(encoding="utf-8")), flags=re.S)
            }
            self.assertTrue(hits <= allowed_runtime, msg=f"{token} leaked to {sorted(hits)}")


if __name__ == "__main__":
    unittest.main()

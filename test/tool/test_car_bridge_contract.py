"""AA-02 static architecture gate for the one-way car telemetry bridge.

Complements the behavioural tests (test/car/**, :car-core and
:app:testCarProtoDebugUnitTest) with source-level invariants that a refactor
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
NON_CAR_FLAVORS = ("field", "rig", "wear")


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
        source = _strip_dart_comments(self.read(PIGEON_INPUT))
        self.assertEqual(len(re.findall(r"@HostApi\s*\(", source)), 1)
        self.assertEqual(re.findall(r"@FlutterApi\s*\(", source), [])
        self.assertEqual(re.findall(r"@EventChannelApi\s*\(", source), [])
        self.assertIn("void publishTelemetryFrame(CarTelemetryMessage frame);", source)

    def test_generated_code_has_no_kotlin_to_dart_api(self):
        kotlin = self.read(GENERATED_KOTLIN)
        dart = self.read(GENERATED_DART)
        # A Pigeon FlutterApi generates a Kotlin class that *calls* Dart and a
        # Dart abstract class with a static setUp; neither may exist.
        self.assertNotIn("class CarTelemetryFlutterApi", kotlin)
        self.assertNotRegex(kotlin, r"class \w+FlutterApi\(")
        self.assertNotRegex(dart, r"abstract class \w+ \{\s*static const MessageCodec")
        self.assertEqual(len(re.findall(r"(?m)^interface \w+", kotlin)), 1)
        self.assertIn("interface CarTelemetryHostApi", kotlin)

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
            and "CarTelemetryHostApi" in p.read_text(encoding="utf-8")
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
            "carbridge",
            "com.cbstudio.telltale.car.",
            "CarTelemetryRuntime",
            "Class.forName",
        ):
            self.assertNotIn(forbidden, source, msg=forbidden)

    def test_every_flavor_has_a_registrar_and_non_car_ones_are_inert(self):
        car = self.read(
            "android/app/src/carProto/kotlin/com/cbstudio/telltale/"
            "FlavorPlatformRegistrar.kt"
        )
        self.assertIn("CarTelemetryHostApi.setUp(", car)
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
            self.assertEqual(imports, ["io.flutter.embedding.engine.FlutterEngine"])

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

    def test_car_core_is_still_car_proto_only(self):
        gradle = self.read("android/app/build.gradle.kts")
        deps = re.findall(r'project\(":car-core"\)', gradle)
        self.assertEqual(len(deps), 1)
        self.assertIn('add("carProtoImplementation", project(":car-core"))', gradle)

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
        self.assertIn("final carProjectionEnabledProvider = Provider<bool>((ref) => false);", runtime)

    def test_drift_gate_and_car_unit_lanes_are_in_full_gate(self):
        gate = self.read("tool/ci/full_gate.sh")
        self.assertIn("run_step car-pigeon-codegen bash tool/ci/verify_car_pigeon_codegen.sh", gate)
        self.assertIn(":car-core:testDebugUnitTest", gate)
        self.assertIn(":app:testCarProtoDebugUnitTest", gate)
        self.assertLess(gate.index("run_step pub-get"), gate.index("car-pigeon-codegen"))

    def test_forbidden_runtime_scope_is_absent(self):
        roots = [
            ROOT / "lib/car",
            ROOT / "android/car-core/src/main",
            ROOT / "android/app/src/carProto",
        ]
        forbidden = (
            "WakeLock",
            "startForeground",
            "FOREGROUND_SERVICE",
            "FlutterEngineCache",
            "CarUxRestrictions",
        )
        for root in roots:
            for path in root.rglob("*"):
                if not path.is_file() or path.suffix not in {".kt", ".dart", ".xml"}:
                    continue
                text = _strip_dart_comments(path.read_text(encoding="utf-8"))
                text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
                for token in forbidden:
                    self.assertNotIn(token, text, msg=f"{token} in {path.relative_to(ROOT)}")


if __name__ == "__main__":
    unittest.main()

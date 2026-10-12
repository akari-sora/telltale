import hashlib
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "seed_gradle_distribution", ROOT / "tool/ci/seed_gradle_distribution.py"
)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

NAME = "gradle-0.0-all.zip"
URL = f"https://services.gradle.org/distributions/{NAME}"
PAYLOAD = b"pinned distribution bytes"


class SeedGradleDistributionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: __import__("shutil").rmtree(self.tmp))
        self.home = self.tmp / "gradle-home"
        self.mirror = self.tmp / "mirror"
        self.mirror.mkdir()
        (self.mirror / NAME).write_bytes(PAYLOAD)

    def properties(self, sha=None, url=URL):
        sha = sha or hashlib.sha256(PAYLOAD).hexdigest()
        path = self.tmp / "gradle-wrapper.properties"
        path.write_text(
            "distributionBase=GRADLE_USER_HOME\n"
            "distributionPath=wrapper/dists\n"
            "zipStoreBase=GRADLE_USER_HOME\n"
            "zipStorePath=wrapper/dists\n"
            f"distributionUrl={url.replace(':', chr(92) + ':', 1)}\n"
            f"distributionSha256Sum={sha}\n"
        )
        return path

    def mirrors(self):
        return (self.mirror.as_uri() + "/missing/{name}", self.mirror.as_uri() + "/{name}")

    def test_repository_wrapper_maps_to_gradle_cache_directory(self):
        props = MODULE.read_properties(ROOT / "android/gradle/wrapper/gradle-wrapper.properties")
        path = MODULE.wrapper_zip_path(Path("/h"), props["distributionUrl"], "wrapper/dists")
        # Gradle's PathAssembler: base36(md5(url)); observed in a real ~/.gradle.
        self.assertEqual(
            path,
            Path("/h/wrapper/dists/gradle-9.3.1-all/9ot9r568e8zfvvd4mn8rbu1j0/gradle-9.3.1-all.zip"),
        )
        self.assertEqual(len(props["distributionSha256Sum"]), 64)

    def test_seeds_only_the_pinned_bytes_after_trying_the_next_mirror(self):
        placed = MODULE.seed(self.properties(), self.home, self.mirrors())
        self.assertIsNotNone(placed)
        self.assertEqual(placed.read_bytes(), PAYLOAD)
        self.assertEqual(placed, MODULE.wrapper_zip_path(self.home, URL, "wrapper/dists"))
        self.assertEqual(sorted(p.name for p in placed.parent.iterdir()), [NAME])

    def test_checksum_mismatch_leaves_the_cache_empty(self):
        placed = MODULE.seed(self.properties(sha="0" * 64), self.home, self.mirrors())
        self.assertIsNone(placed)
        target = MODULE.wrapper_zip_path(self.home, URL, "wrapper/dists")
        self.assertFalse(target.exists())
        self.assertEqual(list(target.parent.iterdir()), [])

    def test_existing_zip_is_not_replaced(self):
        target = MODULE.wrapper_zip_path(self.home, URL, "wrapper/dists")
        target.parent.mkdir(parents=True)
        target.write_bytes(b"already there")
        self.assertEqual(MODULE.seed(self.properties(), self.home, self.mirrors()), target)
        self.assertEqual(target.read_bytes(), b"already there")

    def test_unsupported_configuration_is_skipped(self):
        for props in (
            self.properties(url="https://example.com/gradle-0.0-all.zip"),
            self.properties(sha="abc"),
        ):
            with self.subTest(props=props.read_text()):
                self.assertIsNone(MODULE.seed(props, self.home, self.mirrors()))
        self.assertFalse(self.home.exists())

    def test_main_never_fails_the_gate(self):
        self.assertEqual(MODULE.main(["seed", str(self.tmp / "absent"), str(self.home)]), 0)


if __name__ == "__main__":
    unittest.main()

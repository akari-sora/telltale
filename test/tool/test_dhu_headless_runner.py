#!/usr/bin/env python3
"""Unit tests for tool/dhu_headless_runner.py."""

from __future__ import annotations

import io
from pathlib import Path
import sys
import tempfile
import unittest

# Ensure repo root is on sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from PIL import Image, ImageDraw

from tool.dhu_headless_runner import (
    DEFAULT_CONFIGS_DIR,
    DEFAULT_EVIDENCE_DIR,
    DEFAULT_SCRIPTS_DIR,
    KNOWN_PROFILES,
    KNOWN_SCRIPTS,
    find_dhu_binary,
    list_profiles,
    list_scripts,
    main,
    parse_and_validate_script,
    run_dry_run,
    validate_profile_ini,
    verify_non_black_screen,
)


class DhuHeadlessRunnerTest(unittest.TestCase):
    def test_known_profiles_exist_and_validate(self):
        """Verify all 6 canonical profiles in docs/android-auto/aa-06/configs exist and pass validation."""
        self.assertTrue(DEFAULT_CONFIGS_DIR.is_dir(), f"Config dir not found: {DEFAULT_CONFIGS_DIR}")
        profiles = list_profiles(DEFAULT_CONFIGS_DIR)
        for expected in KNOWN_PROFILES:
            self.assertIn(expected, profiles, f"Expected profile {expected} not found in {profiles.keys()}")
            profile_path = profiles[expected]
            valid, msg, details = validate_profile_ini(profile_path)
            self.assertTrue(valid, f"Profile {expected} failed validation: {msg}")
            self.assertIn("resolution", details)
            self.assertGreater(details["resolution"][0], 0)
            self.assertGreater(details["resolution"][1], 0)
            self.assertGreater(details["dpi"], 0)
            self.assertIn("inputmode", details)

    def test_invalid_profile_ini_fails(self):
        """Verify malformed INI profiles fail validation gracefully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Missing [general]
            p1 = Path(tmpdir) / "missing_gen.ini"
            p1.write_text("[sensors]\nspeed=true\n", encoding="utf-8")
            valid, msg, _ = validate_profile_ini(p1)
            self.assertFalse(valid)
            self.assertIn("Missing [general]", msg)

            # 2. Missing resolution
            p2 = Path(tmpdir) / "missing_res.ini"
            p2.write_text("[general]\ndpi=160\n", encoding="utf-8")
            valid, msg, _ = validate_profile_ini(p2)
            self.assertFalse(valid)
            self.assertIn("resolution", msg)

            # 3. Invalid resolution format
            p3 = Path(tmpdir) / "bad_res.ini"
            p3.write_text("[general]\nresolution=invalid\n", encoding="utf-8")
            valid, msg, _ = validate_profile_ini(p3)
            self.assertFalse(valid)
            self.assertIn("Invalid resolution format", msg)

            # 4. Non-existent file
            p4 = Path(tmpdir) / "non_existent.ini"
            valid, msg, _ = validate_profile_ini(p4)
            self.assertFalse(valid)
            self.assertIn("not found", msg)

    def test_known_scripts_exist_and_parse(self):
        """Verify all 7 canonical scripts in docs/android-auto/aa-06/scripts exist and pass validation."""
        self.assertTrue(DEFAULT_SCRIPTS_DIR.is_dir(), f"Scripts dir not found: {DEFAULT_SCRIPTS_DIR}")
        scripts = list_scripts(DEFAULT_SCRIPTS_DIR)
        for expected in KNOWN_SCRIPTS:
            self.assertIn(expected, scripts, f"Expected script {expected} not found")
            script_path = scripts[expected]
            valid, msg, commands, screenshots = parse_and_validate_script(script_path)
            self.assertTrue(valid, f"Script {expected} failed validation: {msg}")
            self.assertGreater(len(commands), 0)
            self.assertGreater(len(screenshots), 0)

    def test_invalid_script_fails(self):
        """Verify scripts with unknown commands or syntax errors fail validation."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Unknown command
            s1 = Path(tmpdir) / "bad_cmd.txt"
            s1.write_text("sleep 1\nunknown_dhu_cmd_xyz 123\n", encoding="utf-8")
            valid, msg, _, _ = parse_and_validate_script(s1)
            self.assertFalse(valid)
            self.assertIn("unknown DHU command", msg)

            # 2. Screenshot without argument
            s2 = Path(tmpdir) / "bad_shot.txt"
            s2.write_text("screenshot\n", encoding="utf-8")
            valid, msg, _, _ = parse_and_validate_script(s2)
            self.assertFalse(valid)
            self.assertIn("missing target filename", msg)

            # 3. Non-existent script
            s3 = Path(tmpdir) / "non_existent.txt"
            valid, msg, _, _ = parse_and_validate_script(s3)
            self.assertFalse(valid)
            self.assertIn("not found", msg)

    def test_non_black_screen_verifier_pure_black_fails(self):
        """Verify pure black screen is strictly rejected."""
        im = Image.new("RGB", (800, 480), (0, 0, 0))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("Black screen detected", msg)
        self.assertEqual(stats["mean_luminance"], 0.0)
        self.assertEqual(stats["variance"], 0.0)

    def test_non_black_screen_verifier_flat_blank_fails(self):
        """Verify flat uniform screen (zero variance) is strictly rejected."""
        im = Image.new("RGB", (800, 480), (100, 100, 100))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("Blank/flat screen detected", msg)
        self.assertEqual(stats["variance"], 0.0)

    def test_non_black_screen_verifier_transparent_rgba_fails(self):
        """Verify fully transparent RGBA image is strictly rejected."""
        im = Image.new("RGBA", (800, 480), (255, 0, 0, 0))
        valid, msg, _ = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("transparent", msg)

    def test_non_black_screen_verifier_valid_screen_passes(self):
        """Verify rendered screen with genuine UI elements passes."""
        im = Image.new("RGB", (800, 480), (10, 10, 20))
        draw = ImageDraw.Draw(im)
        draw.rectangle([100, 100, 700, 400], fill=(50, 150, 250), outline=(255, 255, 255))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertTrue(valid, msg)
        self.assertGreater(stats["mean_luminance"], 1.0)
        self.assertGreater(stats["variance"], 1.0)

    def test_non_black_screen_verifier_genuine_fixtures(self):
        """Verify all existing repository evidence fixtures pass non-black validation."""
        if not DEFAULT_EVIDENCE_DIR.is_dir():
            self.skipTest("Evidence dir not available")
        evidence_files = list(DEFAULT_EVIDENCE_DIR.glob("*.png"))
        self.assertGreater(len(evidence_files), 0, "No evidence screenshots found")
        for shot in evidence_files:
            valid, msg, stats = verify_non_black_screen(shot)
            self.assertTrue(valid, f"Genuine fixture {shot.name} failed: {msg}")
            self.assertGreater(stats["mean_luminance"], 1.0)
            self.assertGreater(stats["variance"], 1.0)

    def test_dry_run_suite_passes(self):
        """Verify run_dry_run execution returns 0."""
        ret = run_dry_run(
            configs_dir=DEFAULT_CONFIGS_DIR,
            scripts_dir=DEFAULT_SCRIPTS_DIR,
            evidence_dir=DEFAULT_EVIDENCE_DIR,
            verbose=False,
        )
        self.assertEqual(ret, 0)

    def test_main_cli_dry_run_exits_zero(self):
        """Verify main() with --dry-run exits with 0."""
        ret = main(["--dry-run"])
        self.assertEqual(ret, 0)


if __name__ == "__main__":
    unittest.main()

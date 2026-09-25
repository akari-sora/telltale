#!/usr/bin/env python3
"""Unittest wrapper for UDS read-only vectors verification against udsoncan (WS-09, Issue #13 Slice 1)."""
from __future__ import annotations

import unittest
from pathlib import Path

import verify_udsoncan_vectors


class TestUdsoncanVectors(unittest.TestCase):
    def test_all_literal_vectors_pass_against_udsoncan(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        vectors_path = repo_root / "tool/uds_reference/uds_readonly_vectors.json"
        self.assertTrue(vectors_path.is_file(), f"Vectors file missing: {vectors_path}")

        rc = verify_udsoncan_vectors.verify_vectors(vectors_path)
        self.assertEqual(rc, 0, "Vector verification against udsoncan failed")


if __name__ == "__main__":
    unittest.main()

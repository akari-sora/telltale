#!/usr/bin/env python3
"""Unittest wrapper for UDS vectors verification against udsoncan (WS-09, Refs #13)."""
from __future__ import annotations

import unittest
from pathlib import Path

import verify_udsoncan_vectors


class TestUdsoncanVectors(unittest.TestCase):
    def test_all_readonly_vectors_pass_against_udsoncan(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        vectors_path = repo_root / "tool/uds_reference/uds_readonly_vectors.json"
        self.assertTrue(vectors_path.is_file(), f"Vectors file missing: {vectors_path}")

        rc = verify_udsoncan_vectors.verify_vectors(vectors_path)
        self.assertEqual(rc, 0, "Readonly vector verification against udsoncan failed")

    def test_all_dtc_vectors_pass_against_udsoncan(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        vectors_path = repo_root / "tool/uds_reference/uds_dtc_vectors.json"
        self.assertTrue(vectors_path.is_file(), f"Vectors file missing: {vectors_path}")

        rc = verify_udsoncan_vectors.verify_vectors(vectors_path)
        self.assertEqual(rc, 0, "DTC vector verification against udsoncan failed")


if __name__ == "__main__":
    unittest.main()

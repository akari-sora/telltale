#!/usr/bin/env python3
"""Unittest wrapper for UDS transaction vectors verification (WS-09 Slice 3, Refs #13)."""
from __future__ import annotations

import unittest
from pathlib import Path

from verify_uds_transaction_vectors import verify_vectors

HERE = Path(__file__).parent


class TestVerifyUdsTransactionVectors(unittest.TestCase):
    def test_verify_all_transaction_vectors(self) -> None:
        fixture = HERE / "uds_transaction_vectors.json"
        exit_code = verify_vectors(fixture)
        self.assertEqual(exit_code, 0, "All transaction vectors must pass verification")


if __name__ == "__main__":
    unittest.main()

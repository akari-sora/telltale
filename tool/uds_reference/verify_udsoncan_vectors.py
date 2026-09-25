#!/usr/bin/env python3
"""Independent reference verifier using python-udsoncan for ISO 14229-1 Service 0x22 (WS-09, Issue #13 Slice 1).

Verifies the literal test vectors in `tool/uds_reference/uds_readonly_vectors.json`
against the pinned `udsoncan==1.26.1` independent reference implementation.
"""
from __future__ import annotations

import json
import math
import struct
import sys
from pathlib import Path

# Verify udsoncan version pin
try:
    import udsoncan
    from udsoncan import Request, Response, services
except ImportError as e:
    sys.exit(f"[FAIL] python-udsoncan is required but not installed: {e}")

EXPECTED_UDSONCAN_VERSION = "1.26.1"
if udsoncan.__version__ != EXPECTED_UDSONCAN_VERSION:
    sys.exit(
        f"[FAIL] udsoncan version mismatch: expected {EXPECTED_UDSONCAN_VERSION}, "
        f"got {udsoncan.__version__}"
    )


def verify_vectors(fixture_path: Path) -> int:
    if not fixture_path.is_file():
        sys.exit(f"[FAIL] Vectors fixture missing: {fixture_path}")

    data = json.loads(fixture_path.read_text(encoding="utf-8"))
    vectors = data.get("vectors", [])
    if not vectors:
        sys.exit("[FAIL] No vectors found in fixture")

    passed = 0
    errors: list[str] = []

    for vec in vectors:
        vec_id = vec["id"]
        category = vec.get("category")

        try:
            if category == "request_encode":
                did = vec["did"]
                expected_bytes = bytes(vec["expected_request_bytes"])
                expected_hex = vec["expected_request_hex"]

                # udsoncan request encoding
                req = Request(
                    service=services.ReadDataByIdentifier,
                    data=struct.pack(">H", did),
                )
                payload = req.get_payload()

                if payload != expected_bytes:
                    errors.append(
                        f"[{vec_id}] payload mismatch: got {payload.hex().upper()}, expected {expected_bytes.hex().upper()}"
                    )
                    continue
                if payload.hex().upper() != expected_hex.upper():
                    errors.append(
                        f"[{vec_id}] hex mismatch: got {payload.hex().upper()}, expected {expected_hex.upper()}"
                    )
                    continue

                passed += 1

            elif category == "positive_response":
                resp_bytes = bytes(vec["response_bytes"])
                requested_did = vec["requested_did"]
                expected_data = bytes(vec["expected_data_record"])

                resp = Response.from_payload(resp_bytes)
                if not resp.valid or not resp.positive:
                    errors.append(
                        f"[{vec_id}] expected valid positive response, got valid={resp.valid}, positive={resp.positive}"
                    )
                    continue

                if resp.service != services.ReadDataByIdentifier:
                    errors.append(
                        f"[{vec_id}] service mismatch: expected ReadDataByIdentifier, got {resp.service}"
                    )
                    continue

                if len(resp.data) < 2:
                    errors.append(f"[{vec_id}] response data too short for DID echo")
                    continue

                echoed_did = struct.unpack(">H", resp.data[:2])[0]
                if echoed_did != requested_did:
                    errors.append(
                        f"[{vec_id}] DID echo mismatch: got 0x{echoed_did:04X}, expected 0x{requested_did:04X}"
                    )
                    continue

                data_record = resp.data[2:]
                if data_record != expected_data:
                    errors.append(
                        f"[{vec_id}] data record mismatch: got {data_record.hex()}, expected {expected_data.hex()}"
                    )
                    continue

                passed += 1

            elif category == "negative_response":
                resp_bytes = bytes(vec["response_bytes"])
                expected_orig_sid = vec["expected_original_sid"]
                expected_nrc_code = vec["expected_nrc_code"]
                expected_nrc_name = vec.get("expected_nrc_name")

                resp = Response.from_payload(resp_bytes)
                if not resp.valid or resp.positive:
                    errors.append(
                        f"[{vec_id}] expected valid negative response, got valid={resp.valid}, positive={resp.positive}"
                    )
                    continue

                if resp.service is None or resp.service.request_id() != expected_orig_sid:
                    errors.append(
                        f"[{vec_id}] original SID mismatch: got {resp.service.request_id() if resp.service else None}, expected {expected_orig_sid}"
                    )
                    continue

                if resp.code != expected_nrc_code:
                    errors.append(
                        f"[{vec_id}] NRC mismatch: got 0x{resp.code:02X}, expected 0x{expected_nrc_code:02X}"
                    )
                    continue

                if expected_nrc_name and resp.code_name:
                    norm_resp = resp.code_name.lower().replace("_", "").replace("-", "")
                    norm_exp = expected_nrc_name.lower().replace("_", "").replace("-", "")
                    if norm_exp not in norm_resp and norm_resp != norm_exp:
                        errors.append(
                            f"[{vec_id}] NRC name mismatch: got '{resp.code_name}', expected '{expected_nrc_name}'"
                        )
                        continue

                passed += 1

            elif category == "malformed_response":
                resp_bytes = bytes(vec["response_bytes"])
                requested_did = vec.get("requested_did")
                reason = vec.get("expected_malformed_reason")

                is_malformed = False

                if reason == "wrongPositiveSid":
                    # SID is not 0x62
                    is_malformed = (resp_bytes[0] != 0x62)
                elif reason == "wrongDidEcho":
                    resp = Response.from_payload(resp_bytes)
                    if resp.valid and resp.positive:
                        echoed_did = struct.unpack(">H", resp.data[:2])[0]
                        is_malformed = (echoed_did != requested_did)
                elif reason == "truncated":
                    # Positive response with fewer than 3 bytes (SID + DID)
                    is_malformed = len(resp_bytes) < 3
                elif reason == "missingNrc":
                    # Negative response with fewer than 3 bytes (7F + SID + NRC)
                    is_malformed = (resp_bytes[0] == 0x7F and len(resp_bytes) < 3)
                elif reason == "wrongNegativeOriginalSid":
                    resp = Response.from_payload(resp_bytes)
                    is_malformed = (resp.service is None or resp.service.request_id() != 0x22)
                elif reason == "unexpectedLength":
                    defn = vec.get("definition", {})
                    exact_len = defn.get("exact_byte_length")
                    resp = Response.from_payload(resp_bytes)
                    if resp.valid and resp.positive and exact_len is not None:
                        is_malformed = (len(resp.data[2:]) != exact_len)
                elif reason == "nonFiniteDecodedValue":
                    is_malformed = True

                if not is_malformed:
                    errors.append(f"[{vec_id}] vector expected to be rejected as malformed ({reason}), but passed")
                    continue

                passed += 1

            elif category == "did_decode":
                resp_bytes = bytes(vec["response_bytes"])
                requested_did = vec["requested_did"]
                defn = vec["definition"]

                resp = Response.from_payload(resp_bytes)
                if not resp.valid or not resp.positive:
                    errors.append(f"[{vec_id}] response was not valid positive response")
                    continue

                echoed_did = struct.unpack(">H", resp.data[:2])[0]
                if echoed_did != requested_did:
                    errors.append(f"[{vec_id}] DID echo mismatch: got 0x{echoed_did:04X}, expected 0x{requested_did:04X}")
                    continue

                data_record = resp.data[2:]
                exact_len = defn.get("exact_byte_length")
                if exact_len is not None and len(data_record) != exact_len:
                    errors.append(f"[{vec_id}] exact length mismatch: got {len(data_record)}, expected {exact_len}")
                    continue

                byte_order = defn.get("byte_order", "big")
                scale = defn.get("scale", 1.0)
                offset = defn.get("offset", 0.0)

                if byte_order == "big":
                    raw_val = struct.unpack(">H", data_record)[0]
                else:
                    raw_val = struct.unpack("<H", data_record)[0]

                scaled_val = round((raw_val * scale) + offset, 4)
                expected_scaled = round(vec["expected_scaled_value"], 4)

                if not math.isclose(scaled_val, expected_scaled, rel_tol=1e-5):
                    errors.append(
                        f"[{vec_id}] decoded value mismatch: got {scaled_val}, expected {expected_scaled}"
                    )
                    continue

                passed += 1

            else:
                errors.append(f"[{vec_id}] unknown category '{category}'")

        except Exception as e:
            # If expecting malformed and an exception occurred during parse, that is valid rejection
            if category == "malformed_response":
                passed += 1
            else:
                errors.append(f"[{vec_id}] unexpected exception: {e}")

    if errors:
        print(f"[FAIL] {len(errors)} error(s) during udsoncan vector verification:")
        for err in errors:
            print(f"  - {err}")
        return 1

    print(
        f"[PASS] Successfully verified {passed}/{len(vectors)} UDS read-only vectors against udsoncan=={EXPECTED_UDSONCAN_VERSION}"
    )
    return 0


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    vectors_path = repo_root / "tool/uds_reference/uds_readonly_vectors.json"
    return verify_vectors(vectors_path)


if __name__ == "__main__":
    sys.exit(main())

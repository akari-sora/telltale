#!/usr/bin/env python3
"""Independent reference transaction model for ISO 14229-1 UDS (WS-09 Slice 3, Refs #13).

Verifies the literal test vectors in `tool/uds_reference/uds_transaction_vectors.json`
against an independent Python state machine reference model.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional


@dataclass
class Policy:
    p2_timeout_ms: int
    p2_star_timeout_ms: int
    total_timeout_ms: int
    max_busy_repeat_retries: int
    busy_repeat_delay_ms: int
    max_response_pending_count: int


@dataclass
class TransactionOutcome:
    status: str  # success, terminal_negative, busy_retry_exhausted, response_pending_exhausted, timed_out, cancelled, retired, source_mismatch, malformed
    attempts: int
    retries: int
    pending_count: int
    nrc: Optional[int] = None
    original_sid: Optional[int] = None
    timeout_type: Optional[str] = None
    response_hex: Optional[str] = None
    error_message: Optional[str] = None


class PythonUdsTransactionModel:
    """Independent Python implementation of the UDS application transaction state machine."""

    def __init__(self, policy: Policy):
        self.policy = policy

    def run(self, vector: dict[str, Any]) -> TransactionOutcome:
        timeline = list(vector.get("timeline", []))
        cancel_at = vector.get("cancel_at")
        retire_at = vector.get("retire_at")
        expected_responder = vector.get("expected_responder")
        req_service_id = vector["expected_request_bytes"][0]

        attempts = 0
        retries = 0
        pending_count = 0
        elapsed_ms = 0
        is_retry = False
        timeline_idx = 0

        if cancel_at == "before_initial":
            return TransactionOutcome("cancelled", attempts, retries, pending_count)

        while True:
            if elapsed_ms >= self.policy.total_timeout_ms:
                return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

            if is_retry:
                if retries >= self.policy.max_busy_repeat_retries:
                    return TransactionOutcome("busy_retry_exhausted", attempts, retries, pending_count)

                remaining_total = self.policy.total_timeout_ms - elapsed_ms
                if remaining_total <= 0:
                    return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

                delay = min(self.policy.busy_repeat_delay_ms, remaining_total)
                elapsed_ms += delay

                if cancel_at == "during_busy_delay":
                    return TransactionOutcome("cancelled", attempts, retries, pending_count)

                if elapsed_ms >= self.policy.total_timeout_ms:
                    return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

                retries += 1
            else:
                pass

            remaining_before_send = self.policy.total_timeout_ms - elapsed_ms
            if remaining_before_send <= 0:
                return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

            send_budget = min(self.policy.p2_timeout_ms, remaining_before_send)
            attempts += 1

            if timeline_idx >= len(timeline):
                # No more events -> simulated timeout
                elapsed_ms += send_budget
                timeout_type = "total" if elapsed_ms >= self.policy.total_timeout_ms else "p2"
                return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type=timeout_type)

            event = timeline[timeline_idx]
            timeline_idx += 1

            event_type = event.get("type")
            event_delay = event.get("delay_ms", 0)

            if event_type == "send_timeout":
                elapsed_ms += event_delay
                timeout_type = "total" if elapsed_ms >= self.policy.total_timeout_ms else "p2"
                return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type=timeout_type)

            elapsed_ms += event_delay
            if elapsed_ms >= self.policy.total_timeout_ms:
                return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

            if retire_at == "after_send":
                return TransactionOutcome("retired", attempts, retries, pending_count)

            # Process response in event
            resp_bytes = event.get("response_bytes", [])
            src_addr = event.get("source_address")

            # Check source address
            if expected_responder is not None and src_addr is not None and src_addr != expected_responder:
                return TransactionOutcome("source_mismatch", attempts, retries, pending_count)

            # Response processing loop (handles 0x78 continuations)
            current_resp = resp_bytes
            while True:
                if len(current_resp) < 1:
                    return TransactionOutcome("malformed", attempts, retries, pending_count)

                sid = current_resp[0]

                # Negative response
                if sid == 0x7F:
                    if len(current_resp) < 3:
                        return TransactionOutcome("malformed", attempts, retries, pending_count)
                    orig_sid = current_resp[1]
                    nrc = current_resp[2]

                    if orig_sid != req_service_id:
                        return TransactionOutcome("malformed", attempts, retries, pending_count)

                    # NRC 0x21: busyRepeatRequest
                    if nrc == 0x21:
                        if retries >= self.policy.max_busy_repeat_retries:
                            return TransactionOutcome("busy_retry_exhausted", attempts, retries, pending_count)
                        is_retry = True
                        break  # Break inner loop to execute retry delay

                    # NRC 0x78: responsePending
                    if nrc == 0x78:
                        pending_count += 1
                        if pending_count > self.policy.max_response_pending_count:
                            return TransactionOutcome("response_pending_exhausted", attempts, retries, pending_count)

                        if cancel_at == "during_pending_wait":
                            return TransactionOutcome("cancelled", attempts, retries, pending_count)

                        remaining_total = self.policy.total_timeout_ms - elapsed_ms
                        if remaining_total <= 0:
                            return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

                        p2_star_budget = min(self.policy.p2_star_timeout_ms, remaining_total)

                        if timeline_idx >= len(timeline):
                            elapsed_ms += p2_star_budget
                            timeout_type = "total" if elapsed_ms >= self.policy.total_timeout_ms else "p2Star"
                            return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type=timeout_type)

                        cont_event = timeline[timeline_idx]
                        timeline_idx += 1

                        cont_type = cont_event.get("type")
                        cont_delay = cont_event.get("delay_ms", 0)

                        if cont_type == "continuation_timeout":
                            elapsed_ms += cont_delay
                            timeout_type = "total" if elapsed_ms >= self.policy.total_timeout_ms else "p2Star"
                            return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type=timeout_type)

                        elapsed_ms += cont_delay
                        if elapsed_ms >= self.policy.total_timeout_ms:
                            return TransactionOutcome("timed_out", attempts, retries, pending_count, timeout_type="total")

                        current_resp = cont_event.get("response_bytes", [])
                        continue

                    # Terminal Negative Response
                    return TransactionOutcome("terminal_negative", attempts, retries, pending_count, nrc=nrc, original_sid=orig_sid)

                # Positive response
                if req_service_id == 0x22 and sid == 0x62:
                    if len(current_resp) < 3:
                        return TransactionOutcome("malformed", attempts, retries, pending_count)
                    return TransactionOutcome("success", attempts, retries, pending_count, response_hex=bytes(current_resp).hex().upper())

                if req_service_id == 0x19 and sid == 0x59:
                    if len(current_resp) < 2:
                        return TransactionOutcome("malformed", attempts, retries, pending_count)
                    return TransactionOutcome("success", attempts, retries, pending_count, response_hex=bytes(current_resp).hex().upper())

                return TransactionOutcome("malformed", attempts, retries, pending_count)


def verify_vectors(fixture_path: Path) -> int:
    if not fixture_path.is_file():
        sys.exit(f"[FAIL] Fixture not found: {fixture_path}")

    data = json.loads(fixture_path.read_text(encoding="utf-8"))
    vectors = data.get("vectors", [])
    if not vectors:
        sys.exit("[FAIL] No vectors found in fixture")

    passed = 0
    errors: list[str] = []

    for vec in vectors:
        vec_id = vec["id"]
        policy_data = vec["policy"]
        policy = Policy(
            p2_timeout_ms=policy_data["p2_timeout_ms"],
            p2_star_timeout_ms=policy_data["p2_star_timeout_ms"],
            total_timeout_ms=policy_data["total_timeout_ms"],
            max_busy_repeat_retries=policy_data["max_busy_repeat_retries"],
            busy_repeat_delay_ms=policy_data["busy_repeat_delay_ms"],
            max_response_pending_count=policy_data["max_response_pending_count"],
        )

        model = PythonUdsTransactionModel(policy)
        outcome = model.run(vec)

        expected_outcome = vec["expected_outcome"]
        if outcome.status != expected_outcome:
            errors.append(f"[{vec_id}] Status mismatch: got {outcome.status}, expected {expected_outcome}")
            continue

        if outcome.attempts != vec["expected_attempts"]:
            errors.append(f"[{vec_id}] Attempts mismatch: got {outcome.attempts}, expected {vec['expected_attempts']}")
            continue

        if outcome.retries != vec["expected_retries"]:
            errors.append(f"[{vec_id}] Retries mismatch: got {outcome.retries}, expected {vec['expected_retries']}")
            continue

        if outcome.pending_count != vec["expected_pending_count"]:
            errors.append(f"[{vec_id}] Pending count mismatch: got {outcome.pending_count}, expected {vec['expected_pending_count']}")
            continue

        if "expected_nrc" in vec and outcome.nrc != vec["expected_nrc"]:
            errors.append(f"[{vec_id}] NRC mismatch: got {outcome.nrc}, expected {vec['expected_nrc']}")
            continue

        if "expected_timeout_type" in vec and outcome.timeout_type != vec["expected_timeout_type"]:
            errors.append(f"[{vec_id}] Timeout type mismatch: got {outcome.timeout_type}, expected {vec['expected_timeout_type']}")
            continue

        if "expected_response_hex" in vec and outcome.response_hex != vec["expected_response_hex"].upper():
            errors.append(f"[{vec_id}] Response hex mismatch: got {outcome.response_hex}, expected {vec['expected_response_hex']}")
            continue

        passed += 1

    if errors:
        print(f"[FAIL] {len(errors)} error(s) in {fixture_path.name}:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"[PASS] {passed}/{len(vectors)} UDS transaction vectors verified successfully against Python reference model.")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify UDS transaction vectors against Python reference model.")
    parser.add_argument(
        "--fixture",
        type=Path,
        default=Path(__file__).parent / "uds_transaction_vectors.json",
        help="Path to transaction vectors JSON fixture",
    )
    args = parser.parse_args()
    code = verify_vectors(args.fixture)
    sys.exit(code)


if __name__ == "__main__":
    main()

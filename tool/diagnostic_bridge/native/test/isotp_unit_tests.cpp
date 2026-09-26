#include <iostream>
#include <vector>
#include <string>
#include <cassert>
#include <stdexcept>
#include <cstring>
#include "ws10/can_types.hpp"
#include "ws10/syscall_seams.hpp"
#include "ws10/test_fakes.hpp"
#include "ws10/isotp_channel.hpp"

using namespace ws10;

#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "FAIL: " << (msg) << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
      return false; \
    } \
  } while (0)

bool test_u01_can_id_bounds_and_wire() {
  // Standard CAN ID (0..0x7FF)
  CanId std_min(0U, CanIdFormat::kStandard);
  TEST_ASSERT(std_min.id() == 0, "std_min id");
  TEST_ASSERT(!std_min.is_extended(), "std_min not extended");
  TEST_ASSERT(std_min.to_wire_id() == 0, "std_min wire id");

  CanId std_max(0x7FFU, CanIdFormat::kStandard);
  TEST_ASSERT(std_max.id() == 0x7FF, "std_max id");
  TEST_ASSERT(std_max.to_wire_id() == 0x7FF, "std_max wire id");

  // R64-1: 64-bit narrowing prevention test: 4294967587ULL (0x100000123)
  bool narrowing_rejected = false;
  try {
    CanId bad_std(4294967587ULL, CanIdFormat::kStandard);
    (void)bad_std;
  } catch (const std::invalid_argument&) {
    narrowing_rejected = true;
  }
  TEST_ASSERT(narrowing_rejected, "0x100000123ULL must throw and NOT narrow to 0x123");

  bool std_overflow_thrown = false;
  try {
    CanId bad_std(0x800U, CanIdFormat::kStandard);
    (void)bad_std;
  } catch (const std::invalid_argument&) {
    std_overflow_thrown = true;
  }
  TEST_ASSERT(std_overflow_thrown, "std CAN ID > 0x7FF must throw");

  bool std_negative_thrown = false;
  try {
    CanId neg_std(-1, CanIdFormat::kStandard);
    (void)neg_std;
  } catch (const std::invalid_argument&) {
    std_negative_thrown = true;
  }
  TEST_ASSERT(std_negative_thrown, "negative std CAN ID must throw");

  // Extended CAN ID (0..0x1FFFFFFF)
  CanId ext_min(0U, CanIdFormat::kExtended);
  TEST_ASSERT(ext_min.id() == 0, "ext_min id");
  TEST_ASSERT(ext_min.is_extended(), "ext_min extended");
  TEST_ASSERT(ext_min.to_wire_id() == CanId::kCanEffFlag, "ext_min wire id EFF flag");

  CanId ext_max(0x1FFFFFFFU, CanIdFormat::kExtended);
  TEST_ASSERT(ext_max.id() == 0x1FFFFFFF, "ext_max id");
  TEST_ASSERT(ext_max.to_wire_id() == (0x1FFFFFFFU | CanId::kCanEffFlag), "ext_max wire id EFF flag");

  bool ext_overflow_thrown = false;
  try {
    CanId bad_ext(0x20000000U, CanIdFormat::kExtended);
    (void)bad_ext;
  } catch (const std::invalid_argument&) {
    ext_overflow_thrown = true;
  }
  TEST_ASSERT(ext_overflow_thrown, "ext CAN ID > 0x1FFFFFFF must throw");

  bool ext_negative_thrown = false;
  try {
    CanId neg_ext(-5, CanIdFormat::kExtended);
    (void)neg_ext;
  } catch (const std::invalid_argument&) {
    ext_negative_thrown = true;
  }
  TEST_ASSERT(ext_negative_thrown, "negative ext CAN ID must throw");

  return true;
}

bool test_u02_endpoint_spec() {
  CanId tx(0x7E0U, CanIdFormat::kStandard);
  CanId rx(0x7E8U, CanIdFormat::kStandard);
  CanEndpointSpec spec("vcan0", tx, rx);
  TEST_ASSERT(spec.interface_name() == "vcan0", "interface_name match");
  TEST_ASSERT(spec.tx_id() == tx, "tx_id match");
  TEST_ASSERT(spec.rx_id() == rx, "rx_id match");

  // Empty interface name
  bool empty_thrown = false;
  try {
    CanEndpointSpec bad("", tx, rx);
    (void)bad;
  } catch (const std::invalid_argument&) {
    empty_thrown = true;
  }
  TEST_ASSERT(empty_thrown, "empty interface name must throw");

  // Wildcards & whitespace
  for (const char* bad_name : {"vcan*", "can?", "vcan 0", "can\t0", "can\n0"}) {
    bool illegal_thrown = false;
    try {
      CanEndpointSpec bad(bad_name, tx, rx);
      (void)bad;
    } catch (const std::invalid_argument&) {
      illegal_thrown = true;
    }
    TEST_ASSERT(illegal_thrown, std::string("illegal interface name '") + bad_name + "' must throw");
  }

  // Format mismatch (standard TX vs extended RX)
  CanId rx_ext(0x18DAF110U, CanIdFormat::kExtended);
  bool mismatch_thrown = false;
  try {
    CanEndpointSpec bad("vcan0", tx, rx_ext);
    (void)bad;
  } catch (const std::invalid_argument&) {
    mismatch_thrown = true;
  }
  TEST_ASSERT(mismatch_thrown, "format mismatch must throw");

  return true;
}

bool test_u03_application_pdu_bounds() {
  // Empty vector rejected
  bool empty_thrown = false;
  try {
    ApplicationPdu bad(std::vector<uint8_t>{});
    (void)bad;
  } catch (const std::invalid_argument&) {
    empty_thrown = true;
  }
  TEST_ASSERT(empty_thrown, "0-byte PDU must throw");

  // 1 byte valid
  std::vector<uint8_t> one{0x22};
  ApplicationPdu pdu1(one);
  TEST_ASSERT(pdu1.size() == 1, "pdu1 size == 1");
  TEST_ASSERT(pdu1[0] == 0x22, "pdu1[0] == 0x22");

  // 4095 bytes valid
  std::vector<uint8_t> max_pdu(4095, 0xAA);
  ApplicationPdu pdu_max(max_pdu);
  TEST_ASSERT(pdu_max.size() == 4095, "pdu_max size == 4095");

  // 4096 bytes rejected
  std::vector<uint8_t> over_pdu(4096, 0xBB);
  bool over_thrown = false;
  try {
    ApplicationPdu bad(over_pdu);
    (void)bad;
  } catch (const std::invalid_argument&) {
    over_thrown = true;
  }
  TEST_ASSERT(over_thrown, "4096-byte PDU must throw");

  // Index out of range
  bool oob_thrown = false;
  try {
    (void)pdu1[5];
  } catch (const std::out_of_range&) {
    oob_thrown = true;
  }
  TEST_ASSERT(oob_thrown, "out of bounds index must throw");

  return true;
}

bool test_u04_classical_can_frame_bounds() {
  CanId id(0x123U, CanIdFormat::kStandard);
  // 0 bytes valid
  ClassicalCanFrame f0(id, std::vector<uint8_t>{});
  TEST_ASSERT(f0.size() == 0, "f0 size 0");

  // 8 bytes valid
  std::vector<uint8_t> data8{1, 2, 3, 4, 5, 6, 7, 8};
  ClassicalCanFrame f8(id, data8);
  TEST_ASSERT(f8.size() == 8, "f8 size 8");

  // 9 bytes rejected
  std::vector<uint8_t> data9{1, 2, 3, 4, 5, 6, 7, 8, 9};
  bool overflow_thrown = false;
  try {
    ClassicalCanFrame f9(id, data9);
    (void)f9;
  } catch (const std::invalid_argument&) {
    overflow_thrown = true;
  }
  TEST_ASSERT(overflow_thrown, "9 bytes Classical CAN frame must throw");

  return true;
}

bool test_u05_approved_read_grammar() {
  // 1. 0x22 ReadDataByIdentifier (must be exactly 3 bytes: 22 DID_HI DID_LO)
  ApplicationPdu valid_22(std::vector<uint8_t>{0x22, 0xF1, 0x90});
  auto r1 = ApprovedRead::parse(valid_22);
  TEST_ASSERT(r1.kind() == ApprovedReadKind::kReadDataByIdentifier_0x22, "0x22 kind");
  TEST_ASSERT(r1.did() == 0xF190, "0x22 did == 0xF190");

  // 0x22 multi-DID or short rejected
  ApplicationPdu short_22(std::vector<uint8_t>{0x22, 0xF1});
  bool short_22_thrown = false;
  try {
    ApprovedRead::parse(short_22);
  } catch (const std::invalid_argument&) {
    short_22_thrown = true;
  }
  TEST_ASSERT(short_22_thrown, "short 0x22 must throw");

  ApplicationPdu multi_22(std::vector<uint8_t>{0x22, 0xF1, 0x90, 0xF1, 0x80});
  bool multi_22_thrown = false;
  try {
    ApprovedRead::parse(multi_22);
  } catch (const std::invalid_argument&) {
    multi_22_thrown = true;
  }
  TEST_ASSERT(multi_22_thrown, "multi-DID 0x22 must throw");

  // 2. 0x19 0x02 ReportDTCByStatusMask (must be exactly 3 bytes: 19 02 MASK)
  ApplicationPdu valid_19_02(std::vector<uint8_t>{0x19, 0x02, 0x08});
  auto r2 = ApprovedRead::parse(valid_19_02);
  TEST_ASSERT(r2.kind() == ApprovedReadKind::kReportDTCByStatusMask_0x19_02, "19 02 kind");
  TEST_ASSERT(r2.status_mask() == 0x08, "19 02 mask");

  ApplicationPdu bad_19_02(std::vector<uint8_t>{0x19, 0x02, 0x08, 0x00});
  bool bad_19_02_thrown = false;
  try {
    ApprovedRead::parse(bad_19_02);
  } catch (const std::invalid_argument&) {
    bad_19_02_thrown = true;
  }
  TEST_ASSERT(bad_19_02_thrown, "19 02 with 4 bytes must throw");

  // 3. 0x19 0x0A ReportSupportedDTC (must be exactly 2 bytes: 19 0A)
  ApplicationPdu valid_19_0A(std::vector<uint8_t>{0x19, 0x0A});
  auto r3 = ApprovedRead::parse(valid_19_0A);
  TEST_ASSERT(r3.kind() == ApprovedReadKind::kReportSupportedDTC_0x19_0A, "19 0A kind");

  // 4. Prohibited SIDs rejected (e.g. 0x2E Write, 0x10 DiagnosticSessionControl, 0x27 SecurityAccess)
  for (uint8_t prohibited_sid : {0x2E, 0x10, 0x27, 0x31, 0x11, 0x28, 0x85}) {
    ApplicationPdu prohibited_pdu(std::vector<uint8_t>{prohibited_sid, 0x01, 0x02});
    bool thrown = false;
    try {
      ApprovedRead::parse(prohibited_pdu);
    } catch (const std::invalid_argument&) {
      thrown = true;
    }
    TEST_ASSERT(thrown, "prohibited SID must throw");
  }

  return true;
}

bool test_u06_channel_setup_success() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel channel(fake_sys, fake_clock);
  TEST_ASSERT(!channel.is_open(), "initially closed");

  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);

  TEST_ASSERT(channel.is_open(), "open after setup");
  TEST_ASSERT(channel.handle().is_valid(), "handle valid");
  TEST_ASSERT(channel.handle().generation() == 1, "generation == 1");
  TEST_ASSERT(channel.endpoint() != nullptr, "endpoint not null");
  TEST_ASSERT(channel.endpoint()->interface_name() == "vcan0", "endpoint interface");

  // Verify syscalls made (socket, fcntl nonblock, bind)
  TEST_ASSERT(fake_sys->opened_fds.size() == 1, "1 fd opened");
  TEST_ASSERT(fake_sys->bound_addrs.size() == 1, "1 addr bound");
  TEST_ASSERT(fake_sys->bound_addrs[0].can_family == AF_CAN, "AF_CAN");
  TEST_ASSERT(fake_sys->bound_addrs[0].can_ifindex == 42, "ifindex == 42");
  TEST_ASSERT(fake_sys->bound_addrs[0].can_addr.tp.tx_id == 0x7E0, "tx_id == 0x7E0");
  TEST_ASSERT(fake_sys->bound_addrs[0].can_addr.tp.rx_id == 0x7E8, "rx_id == 0x7E8");

  // Double open throws
  bool double_open_thrown = false;
  try {
    channel.open(spec);
  } catch (const std::logic_error&) {
    double_open_thrown = true;
  }
  TEST_ASSERT(double_open_thrown, "double open must throw");

  return true;
}

bool test_u07_channel_setup_failure_rollback() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  fake_sys->bind_errno = ENODEV;

  KernelIsoTpChannel channel(fake_sys);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));

  bool thrown = false;
  try {
    channel.open(spec);
  } catch (const std::system_error&) {
    thrown = true;
  }
  TEST_ASSERT(thrown, "bind failure must throw system_error");
  TEST_ASSERT(!channel.is_open(), "channel must remain closed after failure");
  TEST_ASSERT(!channel.handle().is_valid(), "handle must be invalid");
  TEST_ASSERT(fake_sys->opened_fds.size() == 1, "socket was created");
  TEST_ASSERT(fake_sys->closed_fds.size() == 1, "socket was rolled back and closed");
  TEST_ASSERT(fake_sys->opened_fds[0] == fake_sys->closed_fds[0], "same fd was closed");

  return true;
}

bool test_u08_send_success() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel channel(fake_sys, fake_clock);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);

  ApplicationPdu pdu(std::vector<uint8_t>{0x22, 0xF1, 0x90});
  AttemptId attempt{42};
  auto ctx = OperationContext::with_timeout(attempt, std::chrono::milliseconds(500), *fake_clock);

  WriteReceipt receipt = channel.internal_raw_send_for_testing(pdu, ctx, channel.handle());
  TEST_ASSERT(receipt.attempt_id == attempt, "attempt_id match");
  TEST_ASSERT(receipt.disposition == WriteDisposition::kSubmitted, "disposition submitted");
  TEST_ASSERT(receipt.bytes_written == 3, "bytes_written == 3");
  TEST_ASSERT(fake_sys->written_buffers.size() == 1, "1 buffer written");
  TEST_ASSERT(fake_sys->written_buffers[0] == pdu.bytes(), "written buffer matches pdu");

  return true;
}

bool test_u09_send_bounded_retry_and_timeout() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel channel(fake_sys, fake_clock);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);

  // Script EINTR then EAGAIN then success
  fake_sys->write_script.push_back({-1, EINTR});
  fake_sys->write_script.push_back({-1, EAGAIN});
  fake_sys->write_script.push_back({3, 0});

  ApplicationPdu pdu(std::vector<uint8_t>{0x22, 0xF1, 0x90});
  AttemptId attempt{99};
  auto ctx = OperationContext::with_timeout(attempt, std::chrono::milliseconds(1000), *fake_clock);

  WriteReceipt receipt = channel.internal_raw_send_for_testing(pdu, ctx, channel.handle());
  TEST_ASSERT(receipt.disposition == WriteDisposition::kSubmitted, "submitted after retries");

  // Expiration before send
  AttemptId expired_attempt{100};
  auto expired_ctx = OperationContext::with_timeout(expired_attempt, std::chrono::milliseconds(10), *fake_clock);
  fake_clock->advance(std::chrono::milliseconds(2000));
  WriteReceipt expired_receipt = channel.internal_raw_send_for_testing(pdu, expired_ctx, channel.handle());
  TEST_ASSERT(expired_receipt.disposition == WriteDisposition::kProvenNotSubmitted,
              "expired must be proven not submitted");

  // Single-use attempt rejection
  WriteReceipt dup_receipt = channel.internal_raw_send_for_testing(pdu, ctx, channel.handle());
  TEST_ASSERT(dup_receipt.disposition == WriteDisposition::kProvenNotSubmitted,
              "duplicate attempt ID must be rejected");

  // R64-1: with_timeout negative timeout check
  bool neg_timeout_thrown = false;
  try {
    OperationContext::with_timeout(attempt, std::chrono::milliseconds(-100), *fake_clock);
  } catch (const std::invalid_argument&) {
    neg_timeout_thrown = true;
  }
  TEST_ASSERT(neg_timeout_thrown, "negative timeout must throw invalid_argument");

  return true;
}

bool test_u10_receive_success() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel channel(fake_sys, fake_clock);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);

  std::vector<uint8_t> expected_resp{0x62, 0xF1, 0x90, 0x01, 0x02, 0x03};
  fake_sys->read_script.push_back({expected_resp, 0});

  AttemptId attempt{101};
  auto ctx = OperationContext::with_timeout(attempt, std::chrono::milliseconds(500), *fake_clock);

  ApplicationPdu resp = channel.receive(ctx);
  TEST_ASSERT(resp.bytes() == expected_resp, "received data matches expected");

  // R64-4: 4096-byte datagram truncation detection
  std::vector<uint8_t> oversize_resp(4096, 0x55);
  fake_sys->read_script.push_back({oversize_resp, 0});
  bool truncation_detected = false;
  try {
    channel.receive(ctx);
  } catch (const std::runtime_error& re) {
    if (std::string(re.what()).find("truncated") != std::string::npos) {
      truncation_detected = true;
    }
  }
  TEST_ASSERT(truncation_detected, "4096-byte datagram must be detected as truncated and rejected");

  return true;
}

bool test_u11_terminal_priority_outcome_resolution() {
  // priority order: cancellation > retirement > deadline > cleanup failure > prior outcome
  PrimaryOutcome o1 = resolve_terminal_outcome(
      PrimaryOutcome::kActionError, /*cancelled=*/true, /*retired=*/true,
      /*expired=*/true, /*cleanup_failed=*/true);
  TEST_ASSERT(o1 == PrimaryOutcome::kCancelled, "cancellation dominates all");

  PrimaryOutcome o2 = resolve_terminal_outcome(
      PrimaryOutcome::kActionError, /*cancelled=*/false, /*retired=*/true,
      /*expired=*/true, /*cleanup_failed=*/true);
  TEST_ASSERT(o2 == PrimaryOutcome::kRetired, "retirement dominates deadline and cleanup");

  PrimaryOutcome o3 = resolve_terminal_outcome(
      PrimaryOutcome::kActionError, /*cancelled=*/false, /*retired=*/false,
      /*expired=*/true, /*cleanup_failed=*/true);
  TEST_ASSERT(o3 == PrimaryOutcome::kTimeout, "deadline dominates cleanup and prior");

  PrimaryOutcome o4 = resolve_terminal_outcome(
      PrimaryOutcome::kSuccess, /*cancelled=*/false, /*retired=*/false,
      /*expired=*/false, /*cleanup_failed=*/true);
  TEST_ASSERT(o4 == PrimaryOutcome::kTransportError, "cleanup failure turns success into transport error");

  PrimaryOutcome o5 = resolve_terminal_outcome(
      PrimaryOutcome::kSuccess, /*cancelled=*/false, /*retired=*/false,
      /*expired=*/false, /*cleanup_failed=*/false);
  TEST_ASSERT(o5 == PrimaryOutcome::kSuccess, "prior success preserved");

  return true;
}

bool test_u12_channel_close_and_cleanup() {
  auto fake_sys = std::make_shared<FakeSyscalls>();

  KernelIsoTpChannel channel(fake_sys);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);
  TEST_ASSERT(channel.is_open(), "open");

  // 1. First close
  CleanupOutcome c1 = channel.close();
  TEST_ASSERT(c1 == CleanupOutcome::kSuccess, "first close succeeds");
  TEST_ASSERT(!channel.is_open(), "closed");
  TEST_ASSERT(fake_sys->closed_fds.size() == 1, "closed 1 fd");

  // 2. Double close is idempotent no-op
  CleanupOutcome c2 = channel.close();
  TEST_ASSERT(c2 == CleanupOutcome::kSuccess, "double close succeeds");
  TEST_ASSERT(fake_sys->closed_fds.size() == 1, "no extra close called");

  // 3. Close failure handling
  channel.open(spec);
  fake_sys->close_errno = EIO;
  fake_sys->close_return = -1;
  CleanupOutcome c3 = channel.close();
  TEST_ASSERT(c3 == CleanupOutcome::kFailed, "failed close returns kFailed");
  TEST_ASSERT(!channel.is_open(), "fd still invalidated even on close error");

  // R64-5: Channel is poisoned after failed close and cannot be reopened
  TEST_ASSERT(channel.is_poisoned(), "channel is poisoned after failed close");
  bool poison_prevented = false;
  try {
    channel.open(spec);
  } catch (const std::logic_error&) {
    poison_prevented = true;
  }
  TEST_ASSERT(poison_prevented, "reopening poisoned channel must throw logic_error");

  CleanupOutcome c4 = channel.close();
  TEST_ASSERT(c4 == CleanupOutcome::kFailed, "subsequent close on failed channel remains kFailed");

  return true;
}

bool test_u13_post_poll_revocation_and_handle_validation() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel channel(fake_sys, fake_clock);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);

  HandleId active_handle = channel.handle();
  TEST_ASSERT(channel.validate_handle(active_handle), "active handle must be valid");

  HandleId stale_handle(active_handle.fd(), active_handle.generation() + 1);
  TEST_ASSERT(!channel.validate_handle(stale_handle), "stale generation must be invalid");

  // R64-2: Send with stale handle must be rejected
  AttemptId attempt{777};
  auto ctx = OperationContext::with_timeout(attempt, std::chrono::milliseconds(1000), *fake_clock);
  WriteReceipt r_stale = channel.internal_raw_send_for_testing(
      ApplicationPdu(std::vector<uint8_t>{0x22, 0xF1, 0x90}), ctx, stale_handle);
  TEST_ASSERT(r_stale.disposition == WriteDisposition::kProvenNotSubmitted,
              "send with stale handle must be proven not submitted");

  // R64-3: POLLNVAL revents handled as error
  fake_sys->poll_return = 1;
  fake_sys->poll_revents_override = POLLNVAL;
  WriteReceipt r_nval = channel.internal_raw_send_for_testing(
      ApplicationPdu(std::vector<uint8_t>{0x22, 0xF1, 0x90}), ctx, active_handle);
  TEST_ASSERT(r_nval.disposition == WriteDisposition::kProvenNotSubmitted,
              "POLLNVAL must be proven not submitted");
  fake_sys->poll_revents_override = 0;  // Reset

  // Post-poll cancellation in send
  auto cancel_flag = std::make_shared<bool>(false);
  AttemptId cancel_attempt{778};
  auto cancel_ctx = OperationContext::with_timeout(cancel_attempt, std::chrono::milliseconds(1000), *fake_clock, cancel_flag);
  fake_sys->poll_return = 1;
  *cancel_flag = true;
  WriteReceipt r_cancel = channel.internal_raw_send_for_testing(
      ApplicationPdu(std::vector<uint8_t>{0x22, 0xF1, 0x90}), cancel_ctx, active_handle);
  TEST_ASSERT(r_cancel.disposition == WriteDisposition::kProvenNotSubmitted,
              "post-poll cancellation must be proven not submitted");
  TEST_ASSERT(r_cancel.reason.find("Cancelled") != std::string::npos,
              "cancellation reason must indicate cancellation");

  return true;
}

bool test_u14_exchange_phase_deadline_and_response_payload() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel channel(fake_sys, fake_clock);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  channel.open(spec);

  ApprovedRead req = ApprovedRead::parse(ApplicationPdu(std::vector<uint8_t>{0x22, 0xF1, 0x90}));
  AttemptId attempt{888};

  CanIoBudget budget;
  budget.write_timeout = std::chrono::milliseconds(200);
  budget.read_timeout = std::chrono::milliseconds(300);

  auto ctx = OperationContext::with_timeout(attempt, std::chrono::milliseconds(1000), *fake_clock);

  // R64-2: Exchange with stale handle must be rejected with kAdmissionRejected
  HandleId stale_handle(channel.handle().fd(), channel.handle().generation() + 99);
  ExchangeResult res_stale = channel.exchange(req, ctx, stale_handle, budget);
  TEST_ASSERT(res_stale.primary_outcome == PrimaryOutcome::kAdmissionRejected,
              "exchange with stale handle must be rejected with kAdmissionRejected");

  std::vector<uint8_t> expected_response{0x62, 0xF1, 0x90, 0x01, 0x02};
  fake_sys->read_script.push_back({expected_response, 0});

  ExchangeResult res = channel.exchange(req, ctx, channel.handle(), budget);
  TEST_ASSERT(res.is_success(), "exchange succeeds with phase budgeting");
  TEST_ASSERT(res.primary_outcome == PrimaryOutcome::kSuccess, "primary success");
  // R64-4: ExchangeResult retains actual response payload
  TEST_ASSERT(res.has_response_payload(), "response payload is preserved");
  TEST_ASSERT(res.response_payload == expected_response, "response payload matches expected");

  // R64-2: Duplicate attempt ID on exchange must be rejected with kAdmissionRejected
  ExchangeResult res_dup = channel.exchange(req, ctx, channel.handle(), budget);
  TEST_ASSERT(res_dup.primary_outcome == PrimaryOutcome::kAdmissionRejected,
              "duplicate attempt ID in exchange must be rejected with kAdmissionRejected");

  // R64-4: EILSEQ sequence error mapping
  fake_sys->read_script.push_back({{}, EILSEQ});
  AttemptId attempt_seq{889};
  auto ctx_seq = OperationContext::with_timeout(attempt_seq, std::chrono::milliseconds(1000), *fake_clock);
  ExchangeResult res_seq = channel.exchange(req, ctx_seq, channel.handle(), budget);
  TEST_ASSERT(res_seq.primary_outcome == PrimaryOutcome::kSequenceError,
              "EILSEQ must map to PrimaryOutcome::kSequenceError");

  return true;
}

bool test_u15_move_semantics_and_state_preservation() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  // 1. Move open channel
  KernelIsoTpChannel ch1(fake_sys, fake_clock);
  CanEndpointSpec spec("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                               CanId(0x7E8U, CanIdFormat::kStandard));
  ch1.open(spec);
  int owned_fd = ch1.handle().fd();
  TEST_ASSERT(ch1.is_open(), "ch1 open before move");

  KernelIsoTpChannel ch2(std::move(ch1));
  TEST_ASSERT(!ch1.is_open(), "ch1 closed after move");
  TEST_ASSERT(ch1.handle().fd() == -1, "ch1 fd cleared");
  TEST_ASSERT(ch2.is_open(), "ch2 open after move");
  TEST_ASSERT(ch2.handle().fd() == owned_fd, "ch2 owns original fd");

  // Closing ch2 must close the fd exactly once
  CleanupOutcome cl = ch2.close();
  TEST_ASSERT(cl == CleanupOutcome::kSuccess, "ch2 close succeeds");
  TEST_ASSERT(!ch2.is_open(), "ch2 closed");
  TEST_ASSERT(fake_sys->closed_fds.size() == 1, "underlying fd closed exactly once");

  // 2. Move seen attempts
  KernelIsoTpChannel ch3(fake_sys, fake_clock);
  ch3.open(spec);
  ApprovedRead req = ApprovedRead::parse(ApplicationPdu(std::vector<uint8_t>{0x22, 0xF1, 0x90}));
  AttemptId att1{555};
  auto auth1 = ch3.authorize(req, att1, std::chrono::milliseconds(500));
  fake_sys->read_script.push_back({{0x62, 0xF1, 0x90, 0x01}, 0});
  ch3.exchange(auth1);

  KernelIsoTpChannel ch4(std::move(ch3));
  // Attempt 555 must still be recorded as seen in ch4
  bool dup_attempt_rejected = false;
  try {
    ch4.authorize(req, att1, std::chrono::milliseconds(500));
  } catch (const std::invalid_argument&) {
    dup_attempt_rejected = true;
  }
  TEST_ASSERT(dup_attempt_rejected, "seen attempt preserved across move");

  // 3. Move poisoned state
  fake_sys->close_return = -1;  // simulate close syscall failure
  ch4.close();
  TEST_ASSERT(ch4.is_poisoned(), "ch4 is poisoned after close error");
  KernelIsoTpChannel ch5(std::move(ch4));
  TEST_ASSERT(ch5.is_poisoned(), "ch5 retains poisoned state after move");
  bool reopen_rejected = false;
  try {
    ch5.open(spec);
  } catch (const std::logic_error&) {
    reopen_rejected = true;
  }
  TEST_ASSERT(reopen_rejected, "poisoned channel cannot be opened after move");
  fake_sys->close_return = 0;  // Reset

  // 4. Move assignment overwriting an already-open channel cleans up the existing socket
  KernelIsoTpChannel ch6(fake_sys, fake_clock);
  ch6.open(spec);
  KernelIsoTpChannel ch7(fake_sys, fake_clock);
  ch7.open(spec);
  size_t closes_before = fake_sys->closed_fds.size();
  ch7 = std::move(ch6);
  TEST_ASSERT(fake_sys->closed_fds.size() == closes_before + 1, "move assignment closed overwritten channel");

  return true;
}

bool test_u16_diagnostic_authorization_and_no_raw_bypass() {
  auto fake_sys = std::make_shared<FakeSyscalls>();
  auto fake_clock = std::make_shared<FakeClock>();

  KernelIsoTpChannel ch(fake_sys, fake_clock);
  CanEndpointSpec spec1("vcan0", CanId(0x7E0U, CanIdFormat::kStandard),
                                CanId(0x7E8U, CanIdFormat::kStandard));
  ch.open(spec1);

  ApprovedRead req = ApprovedRead::parse(ApplicationPdu(std::vector<uint8_t>{0x22, 0xF1, 0x90}));
  AttemptId att{123};
  auto auth = ch.authorize(req, att, std::chrono::milliseconds(500));

  TEST_ASSERT(!auth.is_consumed(), "auth not yet consumed");
  TEST_ASSERT(auth.request() == req, "auth request matches");
  TEST_ASSERT(auth.endpoint() == spec1, "auth endpoint matches");
  TEST_ASSERT(auth.handle() == ch.handle(), "auth handle matches");

  // 1. Successful exchange with authorization
  fake_sys->read_script.push_back({{0x62, 0xF1, 0x90, 0x01}, 0});
  ExchangeResult res = ch.exchange(auth);
  TEST_ASSERT(res.is_success(), "exchange with auth succeeds");
  TEST_ASSERT(auth.is_consumed(), "auth marked consumed after exchange");

  // 2. Cannot reuse consumed authorization
  ExchangeResult res2 = ch.exchange(auth);
  TEST_ASSERT(res2.primary_outcome == PrimaryOutcome::kAdmissionRejected,
              "reusing consumed auth must be rejected with kAdmissionRejected");

  // 3. Old authorization cannot be paired with a new endpoint or reopened channel
  ch.close();
  CanEndpointSpec spec2("vcan1", CanId(0x7E0U, CanIdFormat::kStandard),
                                CanId(0x7E8U, CanIdFormat::kStandard));
  ch.open(spec2);

  AttemptId att2{124};
  KernelIsoTpChannel ch_other(fake_sys, fake_clock);
  ch_other.open(spec1);
  auto auth_foreign = ch_other.authorize(req, att2, std::chrono::milliseconds(500));

  ExchangeResult res_foreign = ch.exchange(auth_foreign);
  TEST_ASSERT(res_foreign.primary_outcome == PrimaryOutcome::kAdmissionRejected,
              "auth with mismatched endpoint or handle must be rejected with kAdmissionRejected");

  // 4. Closed channel rejects authorize()
  ch.close();
  bool closed_auth_rejected = false;
  try {
    ch.authorize(req, AttemptId{999}, std::chrono::milliseconds(500));
  } catch (const std::logic_error&) {
    closed_auth_rejected = true;
  }
  TEST_ASSERT(closed_auth_rejected, "authorizing on closed channel throws logic_error");

  return true;
}

bool test_u17_chrono_overflow_and_safe_bounds() {
  auto fake_clock = std::make_shared<FakeClock>();

  // 1. Negative clock epoch does not cause signed integer overflow
  fake_clock->advance(std::chrono::milliseconds(-1000));  // negative epoch
  AttemptId att{901};
  auto ctx_neg = OperationContext::with_timeout(att, std::chrono::milliseconds(100), *fake_clock);
  TEST_ASSERT(!ctx_neg.is_expired(fake_clock->now()), "ctx with negative epoch not expired");

  // 2. checked_phase_deadline with negative now does not overflow
  auto max_tp = std::chrono::steady_clock::time_point::max();
  auto phase_dl = checked_phase_deadline(fake_clock->now(), std::chrono::milliseconds(50), max_tp);
  TEST_ASSERT(phase_dl > fake_clock->now(), "phase deadline advances safely from negative epoch");

  // 3. Near-max clock saturates to max_tp without signed overflow
  auto near_max = max_tp - std::chrono::nanoseconds(50);
  auto sat_dl = checked_phase_deadline(near_max, std::chrono::milliseconds(100), max_tp);
  TEST_ASSERT(sat_dl == max_tp, "phase deadline saturates to max_tp");

  // 4. milliseconds::max() is rejected before arithmetic
  bool max_ms_rejected = false;
  try {
    OperationContext::with_timeout(att, std::chrono::milliseconds::max(), *fake_clock);
  } catch (const std::invalid_argument&) {
    max_ms_rejected = true;
  }
  TEST_ASSERT(max_ms_rejected, "milliseconds::max() rejected before conversion");

  // 5. CanIoBudget with extreme timeout is rejected
  bool budget_rejected = false;
  try {
    CanIoBudget bad_budget(std::chrono::milliseconds::max(),
                           std::chrono::milliseconds(100),
                           std::chrono::milliseconds(100));
  } catch (const std::invalid_argument&) {
    budget_rejected = true;
  }
  TEST_ASSERT(budget_rejected, "CanIoBudget rejects duration > 30 days");

  return true;
}

bool run_deliberate_assertion_failure() {
  auto fake_clock = std::make_shared<FakeClock>();
  TEST_ASSERT(fake_clock->now() == (fake_clock->now() + std::chrono::hours(1)),
              "NEGATIVE CONTROL 1: Deliberate assertion failure in test harness");
  return true;
}

int main(int argc, char** argv) {
  struct TestCase {
    std::string name;
    bool (*fn)();
  };

  std::vector<TestCase> suite = {
      {"U01", test_u01_can_id_bounds_and_wire},
      {"U02", test_u02_endpoint_spec},
      {"U03", test_u03_application_pdu_bounds},
      {"U04", test_u04_classical_can_frame_bounds},
      {"U05", test_u05_approved_read_grammar},
      {"U06", test_u06_channel_setup_success},
      {"U07", test_u07_channel_setup_failure_rollback},
      {"U08", test_u08_send_success},
      {"U09", test_u09_send_bounded_retry_and_timeout},
      {"U10", test_u10_receive_success},
      {"U11", test_u11_terminal_priority_outcome_resolution},
      {"U12", test_u12_channel_close_and_cleanup},
      {"U13", test_u13_post_poll_revocation_and_handle_validation},
      {"U14", test_u14_exchange_phase_deadline_and_response_payload},
      {"U15", test_u15_move_semantics_and_state_preservation},
      {"U16", test_u16_diagnostic_authorization_and_no_raw_bypass},
      {"U17", test_u17_chrono_overflow_and_safe_bounds},
  };

  std::string target_case;

  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "--neg-assertion-fail") {
      std::cerr << "NEGATIVE CONTROL 1: Executing test case with deliberate assertion failure..." << std::endl;
      bool ok = run_deliberate_assertion_failure();
      if (!ok) {
        return 42;
      }
      return 0;
    }
    if (arg == "--neg-unknown-case") {
      std::string target = "U99_non_existent_case";
      std::cerr << "NEGATIVE CONTROL 2: Dispatching to unknown test case '" << target << "'..." << std::endl;
      bool found = false;
      for (const auto& tc : suite) {
        if (target == tc.name) {
          found = true;
          break;
        }
      }
      if (!found) {
        std::cerr << "ERROR: Unknown test case '" << target << "' not registered in suite." << std::endl;
        return 43;
      }
      return 0;
    }
    if (arg == "--neg-zero-match") {
      std::string filter = "^non_existent_filter_pattern$";
      std::cerr << "NEGATIVE CONTROL 3: Filtering tests with pattern '" << filter << "'..." << std::endl;
      size_t matches = 0;
      for (const auto& tc : suite) {
        if (tc.name.find(filter) != std::string::npos) {
          matches++;
        }
      }
      if (matches == 0) {
        std::cerr << "ERROR: 0 tests matched filter (zero-match failure condition)." << std::endl;
        return 44;
      }
      return 0;
    }
    if (arg == "--case") {
      if (i + 1 < argc) {
        target_case = argv[++i];
      } else {
        std::cerr << "ERROR: --case requires a test name argument." << std::endl;
        return 2;
      }
      continue;
    }
    if (arg == "--list") {
      for (const auto& tc : suite) {
        std::cout << tc.name << "\n";
      }
      return 0;
    }

    // R64-6: Any unrecognized option must exit non-zero (never silently ignored)
    std::cerr << "ERROR: Unrecognized argument: " << arg << std::endl;
    return 2;
  }

  // If a specific --case was requested, verify it exists; if not, return non-zero exit code!
  if (!target_case.empty()) {
    for (const auto& tc : suite) {
      if (tc.name == target_case) {
        std::cout << "[ RUN      ] " << tc.name << std::endl;
        bool ok = tc.fn();
        if (ok) {
          std::cout << "[       OK ] " << tc.name << std::endl;
          return 0;
        } else {
          std::cout << "[  FAILED  ] " << tc.name << std::endl;
          return 1;
        }
      }
    }
    std::cerr << "ERROR: Requested test case '" << target_case << "' not found in test suite." << std::endl;
    return 2;
  }

  std::cout << "=== Running WS10-S2 Step 1 Native ISO-TP Unit Tests (U01~U14) ===" << std::endl;

  int passed = 0;
  for (const auto& test : suite) {
    std::cout << "[ RUN      ] " << test.name << std::endl;
    bool ok = false;
    try {
      ok = test.fn();
    } catch (const std::exception& e) {
      std::cerr << "EXCEPTION: " << e.what() << std::endl;
      ok = false;
    } catch (...) {
      std::cerr << "UNKNOWN EXCEPTION" << std::endl;
      ok = false;
    }

    if (ok) {
      std::cout << "[       OK ] " << test.name << std::endl;
      passed++;
    } else {
      std::cout << "[  FAILED  ] " << test.name << std::endl;
      return 1;
    }
  }

  std::cout << "=== PASSED " << passed << "/" << suite.size() << " tests ===" << std::endl;
  return 0;
}

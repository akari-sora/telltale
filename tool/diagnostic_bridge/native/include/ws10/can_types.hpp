#ifndef WS10_CAN_TYPES_HPP_
#define WS10_CAN_TYPES_HPP_

#include <cstdint>
#include <string>
#include <vector>
#include <stdexcept>
#include <algorithm>
#include <sstream>
#include <iomanip>
#include <type_traits>
#include <chrono>
#include <memory>

namespace ws10 {

/// CAN Identifier Format (Standard 11-bit vs Extended 29-bit).
enum class CanIdFormat {
  kStandard,
  kExtended,
};

/// Strongly typed CAN identifier with strict 64-bit bounds validation.
class CanId {
 public:
  static constexpr uint64_t kMaxStandardId = 0x7FFULL;          // 2047
  static constexpr uint64_t kMaxExtendedId = 0x1FFFFFFFULL;      // 536870911
  static constexpr uint32_t kCanEffFlag    = 0x80000000U;       // Linux CAN_EFF_FLAG

  CanId(uint64_t raw_id, CanIdFormat format) : format_(format) {
    validate_and_set(raw_id, format);
  }

  // Explicit constructor for signed integers to reject negative inputs before conversion.
  template <typename T, typename std::enable_if<std::is_signed<T>::value, int>::type = 0>
  CanId(T signed_id, CanIdFormat format) : format_(format) {
    if (signed_id < 0) {
      throw std::invalid_argument("CAN ID cannot be negative: " + std::to_string(signed_id));
    }
    validate_and_set(static_cast<uint64_t>(signed_id), format);
  }

  uint32_t id() const noexcept { return id_; }
  CanIdFormat format() const noexcept { return format_; }
  bool is_extended() const noexcept { return format_ == CanIdFormat::kExtended; }

  /// Converts to Linux SocketCAN wire ID format (EFF flag set for extended).
  uint32_t to_wire_id() const noexcept {
    return is_extended() ? (id_ | kCanEffFlag) : id_;
  }

  bool operator==(const CanId& other) const noexcept {
    return id_ == other.id_ && format_ == other.format_;
  }

  bool operator!=(const CanId& other) const noexcept {
    return !(*this == other);
  }

 private:
  uint32_t id_{0};
  CanIdFormat format_{CanIdFormat::kStandard};

  void validate_and_set(uint64_t raw_id, CanIdFormat format) {
    if (format == CanIdFormat::kStandard) {
      if (raw_id > kMaxStandardId) {
        throw std::invalid_argument("Standard CAN ID exceeds 11-bit limit (0x7FF): 0x" + to_hex(raw_id));
      }
    } else {
      if (raw_id > kMaxExtendedId) {
        throw std::invalid_argument("Extended CAN ID exceeds 29-bit limit (0x1FFFFFFF): 0x" + to_hex(raw_id));
      }
    }
    id_ = static_cast<uint32_t>(raw_id);
  }

  static std::string to_hex(uint64_t val) {
    std::ostringstream ss;
    ss << std::hex << std::uppercase << val;
    return ss.str();
  }
};

/// Bounded Endpoint Specification.
class CanEndpointSpec {
 public:
  CanEndpointSpec(std::string interface_name, CanId tx_id, CanId rx_id)
      : interface_name_(std::move(interface_name)), tx_id_(tx_id), rx_id_(rx_id) {
    validate();
  }

  const std::string& interface_name() const noexcept { return interface_name_; }
  const CanId& tx_id() const noexcept { return tx_id_; }
  const CanId& rx_id() const noexcept { return rx_id_; }

  bool operator==(const CanEndpointSpec& other) const noexcept {
    return interface_name_ == other.interface_name_ &&
           tx_id_ == other.tx_id_ &&
           rx_id_ == other.rx_id_;
  }

  bool operator!=(const CanEndpointSpec& other) const noexcept {
    return !(*this == other);
  }

 private:
  std::string interface_name_;
  CanId tx_id_;
  CanId rx_id_;

  void validate() const {
    if (interface_name_.empty()) {
      throw std::invalid_argument("Interface name cannot be empty.");
    }
    for (char c : interface_name_) {
      if (c == '*' || c == '?' || std::isspace(static_cast<unsigned char>(c))) {
        throw std::invalid_argument("Interface name contains illegal characters (wildcards/whitespace): '" + interface_name_ + "'");
      }
    }
    // TX and RX must have identical identifier width
    if (tx_id_.format() != rx_id_.format()) {
      throw std::invalid_argument("TX and RX identifier formats must match (both standard or both extended).");
    }
  }
};

/// Classical CAN Frame (0..8 data bytes).
class ClassicalCanFrame {
 public:
  static constexpr size_t kMaxPayload = 8;

  ClassicalCanFrame(CanId id, const uint8_t* data, size_t length)
      : id_(id), data_(data, data + length) {
    if (length > kMaxPayload) {
      throw std::invalid_argument("Classical CAN frame data exceeds 8 bytes limit: " + std::to_string(length));
    }
  }

  explicit ClassicalCanFrame(CanId id, std::vector<uint8_t> data)
      : id_(id), data_(std::move(data)) {
    if (data_.size() > kMaxPayload) {
      throw std::invalid_argument("Classical CAN frame data exceeds 8 bytes limit: " + std::to_string(data_.size()));
    }
  }

  const CanId& id() const noexcept { return id_; }
  const std::vector<uint8_t>& data() const noexcept { return data_; }
  size_t size() const noexcept { return data_.size(); }
  const uint8_t* bytes() const noexcept { return data_.data(); }

  bool operator==(const ClassicalCanFrame& other) const noexcept {
    return id_ == other.id_ && data_ == other.data_;
  }

 private:
  CanId id_;
  std::vector<uint8_t> data_;
};

/// Bounded Application PDU (1..4095 bytes). Default empty constructor deleted.
class ApplicationPdu {
 public:
  static constexpr size_t kMinBytes = 1;
  static constexpr size_t kMaxBytes = 4095;

  ApplicationPdu() = delete;

  ApplicationPdu(const uint8_t* data, size_t length) {
    assign(data, length);
  }

  explicit ApplicationPdu(std::vector<uint8_t> data) {
    if (data.size() < kMinBytes || data.size() > kMaxBytes) {
      throw std::invalid_argument("Application PDU length (" + std::to_string(data.size()) + ") outside 1..4095 range.");
    }
    data_ = std::move(data);
  }

  void assign(const uint8_t* data, size_t length) {
    if (data == nullptr || length < kMinBytes || length > kMaxBytes) {
      throw std::invalid_argument("Application PDU length (" + std::to_string(length) + ") outside 1..4095 range.");
    }
    data_.assign(data, data + length);
  }

  size_t size() const noexcept { return data_.size(); }
  const uint8_t* data() const noexcept { return data_.data(); }
  const std::vector<uint8_t>& bytes() const noexcept { return data_; }

  uint8_t operator[](size_t index) const {
    if (index >= data_.size()) {
      throw std::out_of_range("PDU index out of range: " + std::to_string(index));
    }
    return data_[index];
  }

  bool operator==(const ApplicationPdu& other) const noexcept {
    return data_ == other.data_;
  }

 private:
  std::vector<uint8_t> data_;
};

/// Canonical UDS Read Approved Grammar.
enum class ApprovedReadKind {
  kReadDataByIdentifier_0x22,
  kReportDTCByStatusMask_0x19_02,
  kReportSupportedDTC_0x19_0A,
};

/// Approved Read Request Validator.
class ApprovedRead {
 public:
  static ApprovedRead parse(const ApplicationPdu& pdu) {
    if (pdu.size() < 2) {
      throw std::invalid_argument("PDU is too short to be a valid approved UDS read request.");
    }
    uint8_t sid = pdu[0];
    if (sid == 0x22) {
      if (pdu.size() != 3) {
        throw std::invalid_argument("0x22 ReadDataByIdentifier requires exactly 3 bytes (1 SID + 2 DID). Multi-DID or trailing bytes prohibited.");
      }
      uint16_t did = (static_cast<uint16_t>(pdu[1]) << 8) | static_cast<uint16_t>(pdu[2]);
      return ApprovedRead(ApprovedReadKind::kReadDataByIdentifier_0x22, pdu, did, 0);
    } else if (sid == 0x19) {
      uint8_t subfunction = pdu[1];
      if (subfunction == 0x02) {
        if (pdu.size() != 3) {
          throw std::invalid_argument("0x19 0x02 ReportDTCByStatusMask requires exactly 3 bytes (19 02 MASK).");
        }
        return ApprovedRead(ApprovedReadKind::kReportDTCByStatusMask_0x19_02, pdu, 0, pdu[2]);
      } else if (subfunction == 0x0A) {
        if (pdu.size() != 2) {
          throw std::invalid_argument("0x19 0x0A ReportSupportedDTC requires exactly 2 bytes (19 0A).");
        }
        return ApprovedRead(ApprovedReadKind::kReportSupportedDTC_0x19_0A, pdu, 0, 0);
      } else {
        throw std::invalid_argument("Unsupported 0x19 subfunction: 0x" + to_hex(subfunction));
      }
    } else {
      throw std::invalid_argument("Unsupported SID for approved read: 0x" + to_hex(sid) + ". Only 0x22 and 0x19 are approved.");
    }
  }

  ApprovedReadKind kind() const noexcept { return kind_; }
  const ApplicationPdu& pdu() const noexcept { return pdu_; }
  uint16_t did() const noexcept { return did_; }
  uint8_t status_mask() const noexcept { return status_mask_; }

  bool operator==(const ApprovedRead& other) const noexcept {
    return kind_ == other.kind_ && pdu_ == other.pdu_ && did_ == other.did_ && status_mask_ == other.status_mask_;
  }
  bool operator!=(const ApprovedRead& other) const noexcept {
    return !(*this == other);
  }

 private:
  ApprovedReadKind kind_;
  ApplicationPdu pdu_;
  uint16_t did_{0};
  uint8_t status_mask_{0};

  ApprovedRead(ApprovedReadKind kind, ApplicationPdu pdu, uint16_t did, uint8_t status_mask)
      : kind_(kind), pdu_(std::move(pdu)), did_(did), status_mask_(status_mask) {}

  static std::string to_hex(uint8_t val) {
    std::ostringstream ss;
    ss << std::hex << std::uppercase << std::setfill('0') << std::setw(2) << static_cast<int>(val);
    return ss.str();
  }
};

/// Unique diagnostic attempt identifier.
struct AttemptId {
  uint64_t value{0};

  bool operator==(const AttemptId& other) const noexcept { return value == other.value; }
  bool operator!=(const AttemptId& other) const noexcept { return value != other.value; }
};

/// Private resource handle identifier + generation.
/// fd == 0 is a valid descriptor on POSIX.
class HandleId {
 public:
  static constexpr int kInvalidFd = -1;

  HandleId() = default;
  HandleId(int fd, uint64_t generation) : fd_(fd), generation_(generation) {}

  bool is_valid() const noexcept { return fd_ >= 0; }
  int fd() const noexcept { return fd_; }
  uint64_t generation() const noexcept { return generation_; }

  bool operator==(const HandleId& other) const noexcept {
    return fd_ == other.fd_ && generation_ == other.generation_;
  }

  bool operator!=(const HandleId& other) const noexcept {
    return !(*this == other);
  }

 private:
  int fd_{kInvalidFd};
  uint64_t generation_{0};
};

/// Bounded write disposition.
enum class WriteDisposition {
  kSubmitted,
  kProvenNotSubmitted,
  kPartialOrUnknown,
};

/// Write execution receipt.
struct WriteReceipt {
  AttemptId attempt_id;
  size_t bytes_written{0};
  WriteDisposition disposition{WriteDisposition::kProvenNotSubmitted};
  std::string reason;

  bool operator==(const WriteReceipt& other) const noexcept {
    return attempt_id == other.attempt_id &&
           bytes_written == other.bytes_written &&
           disposition == other.disposition &&
           reason == other.reason;
  }
};

/// Bounded single-use diagnostic operation authorization issued by the channel owner.
/// Freezes approved request bytes, exact target endpoint, channel generation,
/// unique attempt ID, and monotonic expiry deadline.
class DiagnosticAuthorization {
 public:
  DiagnosticAuthorization(
      ApprovedRead request,
      CanEndpointSpec endpoint,
      HandleId handle,
      AttemptId attempt_id,
      std::chrono::steady_clock::time_point deadline,
      std::shared_ptr<bool> cancel_flag = nullptr,
      std::shared_ptr<bool> retired_flag = nullptr)
      : request_(std::move(request)),
        endpoint_(std::move(endpoint)),
        handle_(handle),
        attempt_id_(attempt_id),
        deadline_(deadline),
        cancel_flag_(std::move(cancel_flag)),
        retired_flag_(std::move(retired_flag)) {}

  const ApprovedRead& request() const noexcept { return request_; }
  const CanEndpointSpec& endpoint() const noexcept { return endpoint_; }
  const HandleId& handle() const noexcept { return handle_; }
  const AttemptId& attempt_id() const noexcept { return attempt_id_; }
  std::chrono::steady_clock::time_point deadline() const noexcept { return deadline_; }

  bool is_cancelled() const noexcept { return cancel_flag_ && *cancel_flag_; }
  bool is_retired() const noexcept { return retired_flag_ && *retired_flag_; }
  bool is_expired(std::chrono::steady_clock::time_point now) const noexcept { return now >= deadline_; }

  bool is_consumed() const noexcept { return is_consumed_; }
  void mark_consumed() noexcept { is_consumed_ = true; }

  const std::shared_ptr<bool>& cancel_flag() const noexcept { return cancel_flag_; }
  const std::shared_ptr<bool>& retired_flag() const noexcept { return retired_flag_; }

 private:
  ApprovedRead request_;
  CanEndpointSpec endpoint_;
  HandleId handle_;
  AttemptId attempt_id_;
  std::chrono::steady_clock::time_point deadline_;
  std::shared_ptr<bool> cancel_flag_;
  std::shared_ptr<bool> retired_flag_;
  bool is_consumed_{false};
};

/// Primary outcome of an ISO-TP exchange.
enum class PrimaryOutcome {
  kSuccess,
  kTimeout,
  kCancelled,
  kRetired,
  kActionError,
  kSequenceError,
  kTransportError,
  kAdmissionRejected,
  kAdmissonRejected = kAdmissionRejected,
};

/// Cleanup outcome.
enum class CleanupOutcome {
  kSuccess,
  kFailed,
  kSkipped,
};

/// Terminal outcome evaluation priority:
/// cancellation > retirement > deadline > cleanup failure > prior outcome.
inline PrimaryOutcome resolve_terminal_outcome(
    PrimaryOutcome prior_outcome,
    bool is_cancelled,
    bool is_retired,
    bool is_deadline_expired,
    bool cleanup_failed) {
  if (is_cancelled) {
    return PrimaryOutcome::kCancelled;
  }
  if (is_retired) {
    return PrimaryOutcome::kRetired;
  }
  if (is_deadline_expired) {
    return PrimaryOutcome::kTimeout;
  }
  if (cleanup_failed) {
    return PrimaryOutcome::kTransportError;
  }
  return prior_outcome;
}

/// Consolidated Exchange Result retaining actual response payload and failure classification.
struct ExchangeResult {
  PrimaryOutcome primary_outcome{PrimaryOutcome::kActionError};
  WriteReceipt write_receipt;
  CleanupOutcome cleanup_outcome{CleanupOutcome::kSkipped};
  HandleId handle_id;
  std::vector<uint8_t> response_payload;
  int failure_errno{0};
  std::string failure_phase;
  std::string message;

  bool is_success() const noexcept {
    return primary_outcome == PrimaryOutcome::kSuccess;
  }

  bool has_response_payload() const noexcept {
    return !response_payload.empty();
  }
};

}  // namespace ws10

#endif  // WS10_CAN_TYPES_HPP_

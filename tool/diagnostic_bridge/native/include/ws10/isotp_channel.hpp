#ifndef WS10_ISOTP_CHANNEL_HPP_
#define WS10_ISOTP_CHANNEL_HPP_

#include <memory>
#include <chrono>
#include <string>
#include <vector>
#include <stdexcept>
#include "ws10/can_types.hpp"
#include "ws10/syscall_seams.hpp"

namespace ws10 {

constexpr int64_t kMaxSafeTimeoutMs = 86400000LL * 30LL;  // 30 days

/// Configurable I/O and retry budget for ISO-TP operations.
struct CanIoBudget {
  std::chrono::milliseconds open_timeout{1000};
  std::chrono::milliseconds write_timeout{1000};
  std::chrono::milliseconds read_timeout{3000};
  size_t max_retry_count{3};
  std::chrono::milliseconds retry_backoff{10};

  CanIoBudget() = default;

  CanIoBudget(
      std::chrono::milliseconds open_to,
      std::chrono::milliseconds write_to,
      std::chrono::milliseconds read_to,
      size_t max_retry = 3,
      std::chrono::milliseconds backoff = std::chrono::milliseconds(10))
      : open_timeout(open_to),
        write_timeout(write_to),
        read_timeout(read_to),
        max_retry_count(max_retry),
        retry_backoff(backoff) {
    validate();
  }

  void validate() const {
    if (open_timeout.count() <= 0 || open_timeout.count() > kMaxSafeTimeoutMs ||
        write_timeout.count() <= 0 || write_timeout.count() > kMaxSafeTimeoutMs ||
        read_timeout.count() <= 0 || read_timeout.count() > kMaxSafeTimeoutMs) {
      throw std::invalid_argument("CanIoBudget timeouts must be positive and <= 30 days (got open=" +
                                  std::to_string(open_timeout.count()) +
                                  ", write=" + std::to_string(write_timeout.count()) +
                                  ", read=" + std::to_string(read_timeout.count()) + ")");
    }
  }

  bool is_valid() const noexcept {
    return open_timeout.count() > 0 && open_timeout.count() <= kMaxSafeTimeoutMs &&
           write_timeout.count() > 0 && write_timeout.count() <= kMaxSafeTimeoutMs &&
           read_timeout.count() > 0 && read_timeout.count() <= kMaxSafeTimeoutMs;
  }
};

/// Safely computes phase deadline bounded by overall deadline without signed integer overflow.
inline std::chrono::steady_clock::time_point checked_phase_deadline(
    std::chrono::steady_clock::time_point now,
    std::chrono::milliseconds phase_timeout,
    std::chrono::steady_clock::time_point overall_deadline) noexcept {
  if (phase_timeout.count() <= 0) {
    return now;
  }
  if (phase_timeout.count() > kMaxSafeTimeoutMs) {
    return overall_deadline;
  }
  auto max_tp = std::chrono::steady_clock::time_point::max();
  auto dur = std::chrono::duration_cast<std::chrono::steady_clock::duration>(phase_timeout);
  std::chrono::steady_clock::time_point phase_dl =
      (now > max_tp - dur) ? max_tp : (now + dur);
  return std::min(phase_dl, overall_deadline);
}

/// Safely narrows remaining milliseconds into int for poll() without wrapping into negative.
inline int safe_poll_timeout_ms(int64_t remaining_ms) noexcept {
  if (remaining_ms <= 0) {
    return 0;
  }
  constexpr int64_t kMaxInt = 2147483647LL;
  if (remaining_ms > kMaxInt) {
    return static_cast<int>(kMaxInt);
  }
  return static_cast<int>(remaining_ms);
}

/// Operation context carrying diagnostic attempt ID, deadline, and cancellation flags.
class OperationContext {
 public:
  OperationContext(
      AttemptId attempt_id,
      std::chrono::steady_clock::time_point deadline,
      std::shared_ptr<bool> cancel_flag = nullptr,
      std::shared_ptr<bool> retired_flag = nullptr)
      : attempt_id_(attempt_id),
        deadline_(deadline),
        cancel_flag_(std::move(cancel_flag)),
        retired_flag_(std::move(retired_flag)) {}

  static OperationContext with_timeout(
      AttemptId attempt_id,
      std::chrono::milliseconds timeout,
      MonotonicClock& clock,
      std::shared_ptr<bool> cancel_flag = nullptr,
      std::shared_ptr<bool> retired_flag = nullptr) {
    if (timeout.count() < 0) {
      throw std::invalid_argument("Timeout cannot be negative: " + std::to_string(timeout.count()));
    }
    if (timeout.count() > kMaxSafeTimeoutMs) {
      throw std::invalid_argument("Timeout exceeds safe maximum (30 days): " + std::to_string(timeout.count()));
    }
    auto now = clock.now();
    auto max_tp = std::chrono::steady_clock::time_point::max();
    auto dur = std::chrono::duration_cast<std::chrono::steady_clock::duration>(timeout);
    std::chrono::steady_clock::time_point deadline =
        (now > max_tp - dur) ? max_tp : (now + dur);
    return OperationContext(attempt_id, deadline, std::move(cancel_flag), std::move(retired_flag));
  }

  const AttemptId& attempt_id() const noexcept { return attempt_id_; }
  std::chrono::steady_clock::time_point deadline() const noexcept { return deadline_; }

  bool is_cancelled() const noexcept {
    return cancel_flag_ && *cancel_flag_;
  }

  bool is_retired() const noexcept {
    return retired_flag_ && *retired_flag_;
  }

  bool is_expired(std::chrono::steady_clock::time_point now) const noexcept {
    return now >= deadline_;
  }

  const std::shared_ptr<bool>& cancel_flag() const noexcept { return cancel_flag_; }
  const std::shared_ptr<bool>& retired_flag() const noexcept { return retired_flag_; }

 private:
  AttemptId attempt_id_;
  std::chrono::steady_clock::time_point deadline_;
  std::shared_ptr<bool> cancel_flag_;
  std::shared_ptr<bool> retired_flag_;
};

/// Lifecycle and close tracking states for KernelIsoTpChannel.
enum class ChannelCloseState {
  kOpen,
  kClosing,
  kClosed,
  kFailed,
};

/// Single-owner RAII Linux SocketCAN ISO-TP Channel with test seams.
class KernelIsoTpChannel {
 public:
  explicit KernelIsoTpChannel(
      std::shared_ptr<SyscallSeam> sys = nullptr,
      std::shared_ptr<MonotonicClock> clock = nullptr);

  ~KernelIsoTpChannel();

  // Move-only semantics
  KernelIsoTpChannel(const KernelIsoTpChannel&) = delete;
  KernelIsoTpChannel& operator=(const KernelIsoTpChannel&) = delete;
  KernelIsoTpChannel(KernelIsoTpChannel&& other) noexcept;
  KernelIsoTpChannel& operator=(KernelIsoTpChannel&& other) noexcept;

  /// Returns true if socket file descriptor is open and bound.
  bool is_open() const noexcept;

  /// Returns true if channel close failed permanently.
  bool is_poisoned() const noexcept { return is_poisoned_; }

  /// Returns the current handle identifier (fd + generation).
  HandleId handle() const noexcept;

  /// Validates whether the given handle matches the current active handle and is open.
  bool validate_handle(const HandleId& expected) const noexcept;

  /// Returns the current endpoint spec, or nullptr if closed.
  const CanEndpointSpec* endpoint() const noexcept;

  /// Opens and binds the ISO-TP socket to the specified endpoint.
  /// Guarantees rollback (fd closed, handle invalidated) on any setup failure.
  void open(const CanEndpointSpec& spec, const CanIoBudget& budget = CanIoBudget{});

  /// Issues a single-use diagnostic operation authorization binding the approved read to
  /// the active endpoint, channel generation, attempt ID, and monotonic deadline.
  /// Throws std::logic_error if the channel is closed or poisoned.
  /// Throws std::invalid_argument if the AttemptId was already recorded on this channel.
  DiagnosticAuthorization authorize(
      const ApprovedRead& request,
      AttemptId attempt_id,
      std::chrono::milliseconds timeout,
      std::shared_ptr<bool> cancel_flag = nullptr,
      std::shared_ptr<bool> retired_flag = nullptr);

  /// Sends an approved diagnostic request using a DiagnosticAuthorization.
  WriteReceipt send(
      DiagnosticAuthorization& auth,
      const CanIoBudget& budget = CanIoBudget{});

  /// Internal raw send for low-level protocol tests and negative controls.
  /// Public consumers must use authorize() + exchange() or authorize() + send().
  WriteReceipt internal_raw_send_for_testing(
      const ApplicationPdu& pdu,
      const OperationContext& ctx,
      const HandleId& expected_handle,
      const CanIoBudget& budget = CanIoBudget{});

  /// Receives an Application PDU from ISO-TP.
  /// Enforces maximum 4095-byte payload and rejects 4096+ datagram truncation.
  ApplicationPdu receive(
      const OperationContext& ctx,
      const CanIoBudget& budget = CanIoBudget{});

  /// Executes an approved diagnostic read exchange consuming a DiagnosticAuthorization.
  ExchangeResult exchange(
      DiagnosticAuthorization& auth,
      const CanIoBudget& budget = CanIoBudget{});

  /// Executes an approved diagnostic read exchange (send request + await response).
  /// Strictly binds request to active handle and enforces phase-partitioned deadlines.
  ExchangeResult exchange(
      const ApprovedRead& request,
      const OperationContext& ctx,
      const HandleId& expected_handle,
      const CanIoBudget& budget = CanIoBudget{});

  /// Closes the underlying socket. Idempotent.
  CleanupOutcome close() noexcept;

 private:
  std::shared_ptr<SyscallSeam> sys_;
  std::shared_ptr<MonotonicClock> clock_;
  int fd_{-1};
  uint64_t generation_{0};
  std::unique_ptr<CanEndpointSpec> endpoint_;
  ChannelCloseState close_state_{ChannelCloseState::kClosed};
  bool is_poisoned_{false};
  std::vector<uint64_t> seen_attempts_;

  bool has_attempt(const AttemptId& id) const noexcept;
  void record_attempt(const AttemptId& id);
};

}  // namespace ws10

#endif  // WS10_ISOTP_CHANNEL_HPP_

#include "ws10/isotp_channel.hpp"
#include <stdexcept>
#include <system_error>
#include <cstring>
#include <algorithm>

namespace ws10 {

KernelIsoTpChannel::KernelIsoTpChannel(
    std::shared_ptr<SyscallSeam> sys,
    std::shared_ptr<MonotonicClock> clock)
    : sys_(sys ? std::move(sys) : std::make_shared<PosixSyscalls>()),
      clock_(clock ? std::move(clock) : std::make_shared<StdMonotonicClock>()) {}

KernelIsoTpChannel::~KernelIsoTpChannel() {
  close();
}

KernelIsoTpChannel::KernelIsoTpChannel(KernelIsoTpChannel&& other) noexcept
    : sys_(std::move(other.sys_)),
      clock_(std::move(other.clock_)),
      fd_(other.fd_),
      generation_(other.generation_),
      endpoint_(std::move(other.endpoint_)) {
  other.fd_ = -1;
}

KernelIsoTpChannel& KernelIsoTpChannel::operator=(KernelIsoTpChannel&& other) noexcept {
  if (this != &other) {
    close();
    sys_ = std::move(other.sys_);
    clock_ = std::move(other.clock_);
    fd_ = other.fd_;
    generation_ = other.generation_;
    endpoint_ = std::move(other.endpoint_);
    other.fd_ = -1;
  }
  return *this;
}

bool KernelIsoTpChannel::is_open() const noexcept {
  return fd_ >= 0;
}

HandleId KernelIsoTpChannel::handle() const noexcept {
  return HandleId(fd_, generation_);
}

bool KernelIsoTpChannel::validate_handle(const HandleId& expected) const noexcept {
  return is_open() && handle() == expected;
}

const CanEndpointSpec* KernelIsoTpChannel::endpoint() const noexcept {
  return endpoint_.get();
}

bool KernelIsoTpChannel::has_attempt(const AttemptId& id) const noexcept {
  return std::find(seen_attempts_.begin(), seen_attempts_.end(), id.value) != seen_attempts_.end();
}

void KernelIsoTpChannel::record_attempt(const AttemptId& id) {
  seen_attempts_.push_back(id.value);
}

void KernelIsoTpChannel::open(const CanEndpointSpec& spec, const CanIoBudget& budget) {
  if (is_poisoned_) {
    throw std::logic_error("KernelIsoTpChannel close failed previously; channel cannot be reused.");
  }
  if (is_open()) {
    throw std::logic_error("KernelIsoTpChannel is already open.");
  }
  budget.validate();

  unsigned int ifindex = sys_->if_nametoindex(spec.interface_name().c_str());
  if (ifindex == 0) {
    int err = sys_->get_last_error();
    if (err == 0) err = ENODEV;
    throw std::system_error(err, std::generic_category(),
                            "Failed to resolve network interface '" + spec.interface_name() + "'");
  }

  int sock_fd = sys_->socket(PF_CAN, SOCK_DGRAM, CAN_ISOTP);
  if (sock_fd < 0) {
    int err = sys_->get_last_error();
    throw std::system_error(err, std::generic_category(), "Failed to create CAN_ISOTP socket");
  }

  // Setup rollback guard: guarantees fd closed if any setup step throws
  struct RollbackGuard {
    SyscallSeam* sys;
    int fd;
    bool active{true};
    ~RollbackGuard() {
      if (active && fd >= 0) {
        sys->close(fd);
      }
    }
  } guard{sys_.get(), sock_fd, true};

  // Configure nonblocking socket I/O (O_NONBLOCK)
  int fcntl_res = sys_->fcntl(sock_fd, F_SETFL, O_NONBLOCK);
  if (fcntl_res < 0) {
    int err = sys_->get_last_error();
    throw std::system_error(err, std::generic_category(), "Failed to set O_NONBLOCK on CAN_ISOTP socket");
  }

  // Configure close-on-exec (FD_CLOEXEC)
  int cloexec_res = sys_->fcntl(sock_fd, F_SETFD, FD_CLOEXEC);
  if (cloexec_res < 0) {
    int err = sys_->get_last_error();
    throw std::system_error(err, std::generic_category(), "Failed to set FD_CLOEXEC on CAN_ISOTP socket");
  }

  struct sockaddr_can addr;
  std::memset(&addr, 0, sizeof(addr));
  addr.can_family = AF_CAN;
  addr.can_ifindex = static_cast<int>(ifindex);
  addr.can_addr.tp.rx_id = spec.rx_id().to_wire_id();
  addr.can_addr.tp.tx_id = spec.tx_id().to_wire_id();

  int bind_res = sys_->bind(sock_fd, reinterpret_cast<const sockaddr*>(&addr), sizeof(addr));
  if (bind_res < 0) {
    int err = sys_->get_last_error();
    throw std::system_error(err, std::generic_category(),
                            "Failed to bind CAN_ISOTP socket to interface '" + spec.interface_name() + "'");
  }

  // Bind succeeded: disarm rollback guard and claim ownership
  guard.active = false;
  fd_ = sock_fd;
  generation_++;
  endpoint_ = std::make_unique<CanEndpointSpec>(spec);
  close_state_ = ChannelCloseState::kOpen;
  seen_attempts_.clear();
}

WriteReceipt KernelIsoTpChannel::send(
    const ApplicationPdu& pdu,
    const OperationContext& ctx,
    const HandleId& expected_handle,
    const CanIoBudget& budget) {
  if (!is_open()) {
    throw std::logic_error("Cannot send on closed KernelIsoTpChannel.");
  }

  // Validate expected handle authorization unconditionally
  if (!validate_handle(expected_handle)) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "Invalid, stale, or mismatched handle"};
  }

  // Validate single-use attempt: repeated submission with same attempt ID is rejected
  if (has_attempt(ctx.attempt_id())) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "AttemptId already used on this channel"};
  }
  record_attempt(ctx.attempt_id());

  // Validate budget
  if (budget.write_timeout.count() <= 0) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "Invalid non-positive write timeout"};
  }

  // Admission and precondition check before any I/O submission
  if (ctx.is_cancelled()) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "Cancelled before transmission submission"};
  }
  if (ctx.is_retired()) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "Channel retired before transmission submission"};
  }
  auto start_now = clock_->now();
  if (ctx.is_expired(start_now)) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "Deadline expired before transmission submission"};
  }

  // Phase deadline check
  auto send_phase_deadline = checked_phase_deadline(start_now, budget.write_timeout, ctx.deadline());
  if (start_now >= send_phase_deadline) {
    return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                        "Write phase deadline expired before transmission submission"};
  }

  size_t attempts = 0;
  while (attempts <= budget.max_retry_count) {
    attempts++;

    if (ctx.is_cancelled()) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Cancelled during send retry loop"};
    }
    if (ctx.is_retired()) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Channel retired during send retry loop"};
    }
    auto now = clock_->now();
    if (ctx.is_expired(now)) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Deadline expired during send retry loop"};
    }
    if (now >= send_phase_deadline) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Write phase deadline expired during send retry loop"};
    }

    struct pollfd pfd;
    pfd.fd = fd_;
    pfd.events = POLLOUT;
    pfd.revents = 0;

    auto remaining_ms = std::chrono::duration_cast<std::chrono::milliseconds>(send_phase_deadline - now).count();
    int timeout_ms = safe_poll_timeout_ms(remaining_ms);

    int poll_res = sys_->poll(&pfd, 1, timeout_ms);
    if (poll_res < 0) {
      int err = sys_->get_last_error();
      if (err == EINTR) {
        continue;
      }
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "poll failed before write: errno=" + std::to_string(err)};
    }
    if (poll_res == 0) {
      // Timeout on poll
      continue;
    }

    // Check revents for POLLERR, POLLHUP, POLLNVAL
    if (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) {
      int err = sys_->get_last_error();
      if (err == 0) err = EIO;
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "poll returned error revents (POLLERR/POLLHUP/POLLNVAL): " + std::to_string(pfd.revents)};
    }

    // Post-poll re-validation before calling write
    if (ctx.is_cancelled()) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Cancelled post-poll before write submission"};
    }
    if (ctx.is_retired()) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Retired post-poll before write submission"};
    }
    if (ctx.is_expired(clock_->now())) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Deadline expired post-poll before write submission"};
    }
    if (clock_->now() >= send_phase_deadline) {
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                          "Write phase deadline expired post-poll before write submission"};
    }

    ssize_t written = sys_->write(fd_, pdu.data(), pdu.size());
    if (written >= 0) {
      if (static_cast<size_t>(written) == pdu.size()) {
        return WriteReceipt{ctx.attempt_id(), pdu.size(), WriteDisposition::kSubmitted, "OK"};
      } else {
        return WriteReceipt{ctx.attempt_id(), static_cast<size_t>(written),
                            WriteDisposition::kPartialOrUnknown,
                            "Partial ISO-TP write: " + std::to_string(written) + "/" +
                                std::to_string(pdu.size())};
      }
    } else {
      int err = sys_->get_last_error();
      if (err == EINTR || err == EAGAIN || err == EWOULDBLOCK) {
        continue;
      }
      // R64-4: Unknown write error cannot be claimed as proven zero submission
      return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kPartialOrUnknown,
                          "write syscall failed: errno=" + std::to_string(err)};
    }
  }

  return WriteReceipt{ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
                      "Send retries exhausted or write timed out"};
}

ApplicationPdu KernelIsoTpChannel::receive(
    const OperationContext& ctx,
    const CanIoBudget& budget) {
  if (!is_open()) {
    throw std::logic_error("Cannot receive on closed KernelIsoTpChannel.");
  }
  if (budget.read_timeout.count() <= 0) {
    throw std::invalid_argument("Invalid non-positive read timeout in CanIoBudget");
  }

  // Allocate 4096 bytes (4095 max payload + 1 sentinel byte) to detect truncation
  std::vector<uint8_t> buffer(ApplicationPdu::kMaxBytes + 1);
  size_t attempts = 0;
  const size_t max_attempts = budget.max_retry_count + 10;
  auto rx_start = clock_->now();
  auto rx_phase_deadline = checked_phase_deadline(rx_start, budget.read_timeout, ctx.deadline());

  while (attempts < max_attempts) {
    attempts++;

    if (ctx.is_cancelled()) {
      throw std::runtime_error("Operation cancelled during receive");
    }
    if (ctx.is_retired()) {
      throw std::runtime_error("Channel retired during receive");
    }
    auto now = clock_->now();
    if (ctx.is_expired(now) || now >= rx_phase_deadline) {
      throw std::runtime_error("Deadline expired during receive");
    }

    struct pollfd pfd;
    pfd.fd = fd_;
    pfd.events = POLLIN;
    pfd.revents = 0;

    auto remaining_ms = std::chrono::duration_cast<std::chrono::milliseconds>(rx_phase_deadline - now).count();
    int timeout_ms = safe_poll_timeout_ms(remaining_ms);

    int poll_res = sys_->poll(&pfd, 1, timeout_ms);
    if (poll_res < 0) {
      int err = sys_->get_last_error();
      if (err == EINTR) {
        continue;
      }
      throw std::system_error(err, std::generic_category(), "poll failed during receive");
    }
    if (poll_res == 0) {
      if (ctx.is_expired(clock_->now()) || clock_->now() >= rx_phase_deadline) {
        throw std::runtime_error("Deadline expired during receive");
      }
      continue;
    }

    // Check revents for POLLERR, POLLHUP, POLLNVAL
    if (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) {
      int err = sys_->get_last_error();
      if (err == 0) err = EIO;
      throw std::system_error(err, std::generic_category(),
                              "poll revents error during receive: " + std::to_string(pfd.revents));
    }

    // Post-poll re-validation before calling read
    if (ctx.is_cancelled()) {
      throw std::runtime_error("Operation cancelled post-poll before read");
    }
    if (ctx.is_retired()) {
      throw std::runtime_error("Channel retired post-poll before read");
    }
    if (ctx.is_expired(clock_->now()) || clock_->now() >= rx_phase_deadline) {
      throw std::runtime_error("Deadline expired post-poll before read");
    }

    ssize_t n = sys_->read(fd_, buffer.data(), buffer.size());
    if (n > 0) {
      if (static_cast<size_t>(n) > ApplicationPdu::kMaxBytes) {
        throw std::runtime_error("ISO-TP datagram truncated: received 4096+ bytes exceeding 4095-byte maximum payload");
      }
      return ApplicationPdu(buffer.data(), static_cast<size_t>(n));
    } else if (n < 0) {
      int err = sys_->get_last_error();
      if (err == EINTR || err == EAGAIN || err == EWOULDBLOCK) {
        continue;
      }
      if (err == EILSEQ) {
        throw std::system_error(EILSEQ, std::generic_category(), "ISO-TP sequence error (EILSEQ)");
      }
      throw std::system_error(err, std::generic_category(), "read failed from ISO-TP socket");
    } else {
      throw std::runtime_error("Socket closed by peer (EOF)");
    }
  }

  throw std::runtime_error("Receive timed out or retries exhausted");
}

ExchangeResult KernelIsoTpChannel::exchange(
    const ApprovedRead& request,
    const OperationContext& ctx,
    const HandleId& expected_handle,
    const CanIoBudget& budget) {
  ExchangeResult res;
  res.handle_id = handle();
  res.cleanup_outcome = CleanupOutcome::kSkipped;

  // Validate expected handle authorization unconditionally
  if (!validate_handle(expected_handle)) {
    res.write_receipt = WriteReceipt{
        ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
        "Invalid, stale, or mismatched handle for exchange"};
    res.primary_outcome = PrimaryOutcome::kAdmissionRejected;
    res.message = res.write_receipt.reason;
    return res;
  }

  // Validate single-use attempt: repeated submission with same attempt ID is rejected
  if (has_attempt(ctx.attempt_id())) {
    res.write_receipt = WriteReceipt{
        ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
        "AttemptId already used on this channel"};
    res.primary_outcome = PrimaryOutcome::kAdmissionRejected;
    res.message = res.write_receipt.reason;
    return res;
  }

  // Validate budget
  if (budget.write_timeout.count() <= 0 || budget.read_timeout.count() <= 0) {
    res.write_receipt = WriteReceipt{
        ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
        "Invalid non-positive timeout in CanIoBudget"};
    res.primary_outcome = PrimaryOutcome::kActionError;
    res.message = res.write_receipt.reason;
    return res;
  }

  auto start_now = clock_->now();
  if (ctx.is_expired(start_now)) {
    res.write_receipt = WriteReceipt{
        ctx.attempt_id(), 0, WriteDisposition::kProvenNotSubmitted,
        "Deadline expired before exchange initiation"};
    res.primary_outcome = resolve_terminal_outcome(
        PrimaryOutcome::kTimeout, ctx.is_cancelled(), ctx.is_retired(), true, false);
    res.message = res.write_receipt.reason;
    return res;
  }

  // Phase-budgeting: separate write phase and read phase deadlines within total budget
  auto send_deadline = checked_phase_deadline(start_now, budget.write_timeout, ctx.deadline());
  OperationContext send_ctx(ctx.attempt_id(), send_deadline, ctx.cancel_flag(), ctx.retired_flag());

  // 1. Submit Request PDU bound to verified handle
  res.write_receipt = send(request.pdu(), send_ctx, expected_handle, budget);
  if (res.write_receipt.disposition != WriteDisposition::kSubmitted) {
    bool cancelled = ctx.is_cancelled();
    bool retired = ctx.is_retired();
    bool expired = ctx.is_expired(clock_->now()) || (clock_->now() >= send_deadline);
    PrimaryOutcome outcome = (res.write_receipt.disposition == WriteDisposition::kProvenNotSubmitted)
                                 ? PrimaryOutcome::kActionError
                                 : PrimaryOutcome::kTransportError;
    res.primary_outcome = resolve_terminal_outcome(outcome, cancelled, retired, expired, false);
    res.message = res.write_receipt.reason;
    return res;
  }

  // 2. Await Response PDU with read phase deadline
  auto rx_now = clock_->now();
  auto rx_deadline = checked_phase_deadline(rx_now, budget.read_timeout, ctx.deadline());
  OperationContext rx_ctx(ctx.attempt_id(), rx_deadline, ctx.cancel_flag(), ctx.retired_flag());

  try {
    ApplicationPdu resp = receive(rx_ctx, budget);

    // Pre-publication verification: verify cancellation or deadline hasn't elapsed after receive
    if (ctx.is_cancelled()) {
      res.primary_outcome = PrimaryOutcome::kCancelled;
      res.message = "Cancelled post-receive before result publication";
      return res;
    }
    if (ctx.is_retired()) {
      res.primary_outcome = PrimaryOutcome::kRetired;
      res.message = "Retired post-receive before result publication";
      return res;
    }
    if (ctx.is_expired(clock_->now()) || clock_->now() >= rx_deadline) {
      res.primary_outcome = PrimaryOutcome::kTimeout;
      res.message = "Deadline expired post-receive before result publication";
      return res;
    }

    res.primary_outcome = PrimaryOutcome::kSuccess;
    res.response_payload = resp.bytes();
    res.message = "OK (" + std::to_string(resp.size()) + " bytes received)";
  } catch (const std::system_error& se) {
    res.failure_errno = se.code().value();
    res.failure_phase = "receive";
    bool cancelled = ctx.is_cancelled();
    bool retired = ctx.is_retired();
    bool expired = ctx.is_expired(clock_->now()) || clock_->now() >= rx_deadline;
    PrimaryOutcome outcome = (se.code().value() == EILSEQ)
                                 ? PrimaryOutcome::kSequenceError
                                 : PrimaryOutcome::kTransportError;
    res.primary_outcome = resolve_terminal_outcome(outcome, cancelled, retired, expired, false);
    res.message = se.what();
  } catch (const std::exception& e) {
    res.failure_phase = "receive";
    bool cancelled = ctx.is_cancelled();
    bool retired = ctx.is_retired();
    bool expired = ctx.is_expired(clock_->now()) || clock_->now() >= rx_deadline;
    PrimaryOutcome outcome = expired ? PrimaryOutcome::kTimeout : PrimaryOutcome::kTransportError;
    res.primary_outcome = resolve_terminal_outcome(outcome, cancelled, retired, expired, false);
    res.message = e.what();
  }

  return res;
}

CleanupOutcome KernelIsoTpChannel::close() noexcept {
  if (close_state_ == ChannelCloseState::kClosed) {
    return CleanupOutcome::kSuccess;
  }
  if (close_state_ == ChannelCloseState::kFailed) {
    return CleanupOutcome::kFailed;
  }
  if (close_state_ == ChannelCloseState::kClosing) {
    return CleanupOutcome::kSkipped;
  }
  close_state_ = ChannelCloseState::kClosing;

  if (fd_ < 0) {
    close_state_ = ChannelCloseState::kClosed;
    return CleanupOutcome::kSuccess;
  }
  int old_fd = fd_;
  fd_ = -1;
  endpoint_.reset();

  int res = sys_->close(old_fd);
  if (res < 0) {
    close_state_ = ChannelCloseState::kFailed;
    is_poisoned_ = true;
    return CleanupOutcome::kFailed;
  }
  close_state_ = ChannelCloseState::kClosed;
  return CleanupOutcome::kSuccess;
}

}  // namespace ws10

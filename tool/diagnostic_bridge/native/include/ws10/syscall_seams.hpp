#ifndef WS10_SYSCALL_SEAMS_HPP_
#define WS10_SYSCALL_SEAMS_HPP_

#include <cstdint>
#include <cstddef>
#include <string>
#include <vector>
#include <memory>
#include <chrono>
#include <cerrno>
#include <cstring>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#include <net/if.h>

#if defined(__linux__)
#include <linux/can.h>
#include <linux/can/isotp.h>
#else
// Portable compatibility shims for non-Linux platforms (e.g. macOS test runner)
#ifndef AF_CAN
#define AF_CAN 29
#endif
#ifndef PF_CAN
#define PF_CAN AF_CAN
#endif
#ifndef CAN_ISOTP
#define CAN_ISOTP 6
#endif
#ifndef SOL_CAN_ISOTP
#define SOL_CAN_ISOTP 106
#endif
#ifndef CAN_ISOTP_OPTS
#define CAN_ISOTP_OPTS 1
#endif
#ifndef CAN_EFF_FLAG
#define CAN_EFF_FLAG 0x80000000U
#endif

#ifndef HAVE_SOCKADDR_CAN
#define HAVE_SOCKADDR_CAN
struct sockaddr_can {
  sa_family_t can_family;
  int can_ifindex;
  union {
    struct { uint32_t rx_id, tx_id; } tp;
  } can_addr;
};
#endif

#ifndef HAVE_CAN_ISOTP_OPTIONS
#define HAVE_CAN_ISOTP_OPTIONS
struct can_isotp_options {
  uint32_t flags;
  uint32_t frame_txtime;
  uint8_t ext_address;
  uint8_t txpad_content;
  uint8_t rxpad_content;
  uint8_t rx_ext_address;
};
#endif
#endif

namespace ws10 {

/// Monotonic Clock abstraction for deterministic time testing.
class MonotonicClock {
 public:
  virtual ~MonotonicClock() = default;
  virtual std::chrono::steady_clock::time_point now() = 0;
};

/// Real wall/steady clock implementation using std::chrono.
class StdMonotonicClock : public MonotonicClock {
 public:
  std::chrono::steady_clock::time_point now() override {
    return std::chrono::steady_clock::now();
  }
};

/// Low-level system call abstraction seam.
class SyscallSeam {
 public:
  virtual ~SyscallSeam() = default;

  virtual int socket(int domain, int type, int protocol) = 0;
  virtual int close(int fd) = 0;
  virtual int bind(int sockfd, const struct sockaddr* addr, socklen_t addrlen) = 0;
  virtual int setsockopt(int sockfd, int level, int optname, const void* optval, socklen_t optlen) = 0;
  virtual int fcntl(int fd, int cmd, int arg) = 0;
  virtual ssize_t write(int fd, const void* buf, size_t count) = 0;
  virtual ssize_t read(int fd, void* buf, size_t count) = 0;
  virtual int poll(struct pollfd* fds, nfds_t nfds, int timeout_ms) = 0;
  virtual unsigned int if_nametoindex(const char* ifname) = 0;
  virtual int get_last_error() const = 0;
  virtual void set_last_error(int err) = 0;
};

/// Production POSIX syscall implementation.
class PosixSyscalls : public SyscallSeam {
 public:
  int socket(int domain, int type, int protocol) override {
    int res = ::socket(domain, type, protocol);
    if (res < 0) last_error_ = errno;
    return res;
  }

  int close(int fd) override {
    int res = ::close(fd);
    if (res < 0) last_error_ = errno;
    return res;
  }

  int bind(int sockfd, const struct sockaddr* addr, socklen_t addrlen) override {
    int res = ::bind(sockfd, addr, addrlen);
    if (res < 0) last_error_ = errno;
    return res;
  }

  int setsockopt(int sockfd, int level, int optname, const void* optval, socklen_t optlen) override {
    int res = ::setsockopt(sockfd, level, optname, optval, optlen);
    if (res < 0) last_error_ = errno;
    return res;
  }

  int fcntl(int fd, int cmd, int arg) override {
    int res = ::fcntl(fd, cmd, arg);
    if (res < 0) last_error_ = errno;
    return res;
  }

  ssize_t write(int fd, const void* buf, size_t count) override {
    ssize_t res = ::write(fd, buf, count);
    if (res < 0) last_error_ = errno;
    return res;
  }

  ssize_t read(int fd, void* buf, size_t count) override {
    ssize_t res = ::read(fd, buf, count);
    if (res < 0) last_error_ = errno;
    return res;
  }

  int poll(struct pollfd* fds, nfds_t nfds, int timeout_ms) override {
    int res = ::poll(fds, nfds, timeout_ms);
    if (res < 0) last_error_ = errno;
    return res;
  }

  unsigned int if_nametoindex(const char* ifname) override {
    unsigned int res = ::if_nametoindex(ifname);
    if (res == 0) last_error_ = errno;
    return res;
  }

  int get_last_error() const override { return last_error_; }
  void set_last_error(int err) override { last_error_ = err; }

 private:
  int last_error_{0};
};

}  // namespace ws10

#endif  // WS10_SYSCALL_SEAMS_HPP_

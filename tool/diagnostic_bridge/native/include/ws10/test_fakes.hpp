#ifndef WS10_TEST_FAKES_HPP_
#define WS10_TEST_FAKES_HPP_

#include "ws10/syscall_seams.hpp"
#include <vector>
#include <deque>
#include <string>
#include <cstring>
#include <algorithm>

namespace ws10 {

/// Controllable Fake Clock for unit tests.
class FakeClock : public MonotonicClock {
 public:
  explicit FakeClock(std::chrono::steady_clock::time_point initial_time =
                         std::chrono::steady_clock::time_point{})
      : current_time_(initial_time) {}

  std::chrono::steady_clock::time_point now() override {
    return current_time_;
  }

  void advance(std::chrono::milliseconds ms) {
    current_time_ += ms;
  }

  void set_time(std::chrono::steady_clock::time_point tp) {
    current_time_ = tp;
  }

 private:
  std::chrono::steady_clock::time_point current_time_;
};

/// Scriptable Fake Syscalls for unit testing.
class FakeSyscalls : public SyscallSeam {
 public:
  struct ScriptedWrite {
    ssize_t return_val{0};
    int errno_val{0};
  };

  struct ScriptedRead {
    std::vector<uint8_t> data;
    int errno_val{0};
  };

  int next_fd{100};
  int socket_return{0};      // 0 means auto-allocate next_fd
  int socket_errno{0};

  int bind_return{0};
  int bind_errno{0};

  int setsockopt_return{0};
  int setsockopt_errno{0};

  int close_return{0};
  int close_errno{0};

  int fcntl_return{0};
  int fcntl_errno{0};

  unsigned int if_nametoindex_return{42};
  int if_nametoindex_errno{0};

  int poll_return{1};
  int poll_errno{0};
  short poll_revents_override{0};

  std::vector<std::string> call_log;
  std::vector<int> opened_fds;
  std::vector<int> closed_fds;
  std::vector<sockaddr_can> bound_addrs;
  std::vector<std::vector<uint8_t>> written_buffers;

  std::deque<ScriptedWrite> write_script;
  std::deque<ScriptedRead> read_script;

  int socket(int domain, int type, int protocol) override {
    (void)domain; (void)type; (void)protocol;
    call_log.push_back("socket");
    if (socket_errno != 0) {
      last_error_ = socket_errno;
      return -1;
    }
    int fd = socket_return != 0 ? socket_return : next_fd++;
    opened_fds.push_back(fd);
    return fd;
  }

  int close(int fd) override {
    call_log.push_back("close(" + std::to_string(fd) + ")");
    closed_fds.push_back(fd);
    if (close_errno != 0) {
      last_error_ = close_errno;
      return close_return != 0 ? close_return : -1;
    }
    return close_return;
  }

  int bind(int sockfd, const struct sockaddr* addr, socklen_t addrlen) override {
    (void)sockfd; (void)addrlen;
    call_log.push_back("bind");
    if (addr && addrlen >= sizeof(sockaddr_can)) {
      bound_addrs.push_back(*reinterpret_cast<const sockaddr_can*>(addr));
    }
    if (bind_errno != 0) {
      last_error_ = bind_errno;
      return bind_return != 0 ? bind_return : -1;
    }
    return bind_return;
  }

  int setsockopt(int sockfd, int level, int optname, const void* optval, socklen_t optlen) override {
    (void)sockfd; (void)level; (void)optname; (void)optval; (void)optlen;
    call_log.push_back("setsockopt");
    if (setsockopt_errno != 0) {
      last_error_ = setsockopt_errno;
      return setsockopt_return != 0 ? setsockopt_return : -1;
    }
    return setsockopt_return;
  }

  int fcntl(int fd, int cmd, int arg) override {
    (void)fd; (void)cmd; (void)arg;
    call_log.push_back("fcntl");
    if (fcntl_errno != 0) {
      last_error_ = fcntl_errno;
      return fcntl_return != 0 ? fcntl_return : -1;
    }
    return fcntl_return;
  }

  ssize_t write(int fd, const void* buf, size_t count) override {
    (void)fd;
    call_log.push_back("write(" + std::to_string(count) + ")");
    if (!write_script.empty()) {
      auto scripted = write_script.front();
      write_script.pop_front();
      if (scripted.errno_val != 0) {
        last_error_ = scripted.errno_val;
        return scripted.return_val;
      }
      if (buf && count > 0) {
        const uint8_t* p = reinterpret_cast<const uint8_t*>(buf);
        written_buffers.emplace_back(p, p + count);
      }
      return scripted.return_val;
    }

    if (buf && count > 0) {
      const uint8_t* p = reinterpret_cast<const uint8_t*>(buf);
      written_buffers.emplace_back(p, p + count);
    }
    return static_cast<ssize_t>(count);
  }

  ssize_t read(int fd, void* buf, size_t count) override {
    (void)fd;
    call_log.push_back("read");
    if (!read_script.empty()) {
      auto scripted = read_script.front();
      read_script.pop_front();
      if (scripted.errno_val != 0) {
        last_error_ = scripted.errno_val;
        return -1;
      }
      size_t to_copy = std::min(count, scripted.data.size());
      if (buf && to_copy > 0) {
        std::memcpy(buf, scripted.data.data(), to_copy);
      }
      return static_cast<ssize_t>(to_copy);
    }

    // Default: no data available (EAGAIN)
    last_error_ = EAGAIN;
    return -1;
  }

  int poll(struct pollfd* fds, nfds_t nfds, int timeout_ms) override {
    (void)timeout_ms;
    call_log.push_back("poll");
    if (poll_errno != 0) {
      last_error_ = poll_errno;
      return -1;
    }
    if (poll_return > 0 && fds && nfds > 0) {
      for (nfds_t i = 0; i < nfds; ++i) {
        if (poll_revents_override != 0) {
          fds[i].revents = poll_revents_override;
        } else {
          fds[i].revents = fds[i].events;
        }
      }
    }
    return poll_return;
  }

  unsigned int if_nametoindex(const char* ifname) override {
    call_log.push_back(std::string("if_nametoindex(") + (ifname ? ifname : "") + ")");
    if (if_nametoindex_errno != 0) {
      last_error_ = if_nametoindex_errno;
      return 0;
    }
    return if_nametoindex_return;
  }

  int get_last_error() const override { return last_error_; }
  void set_last_error(int err) override { last_error_ = err; }

 private:
  int last_error_{0};
};

}  // namespace ws10

#endif  // WS10_TEST_FAKES_HPP_

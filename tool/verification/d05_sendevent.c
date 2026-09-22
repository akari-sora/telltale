#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>

static void emit(int fd, int type, int code, int val) {
    struct input_event ie;
    memset(&ie, 0, sizeof(ie));
    ie.type = type;
    ie.code = code;
    ie.value = val;
    if (write(fd, &ie, sizeof(ie)) < 0) {
        // ignore write error
    }
}

int main(int argc, char **argv) {
    int is_power = 0;
    if (strstr(argv[0], "power") || strstr(argv[0], "sleep")) {
        is_power = 1;
    }
    int start_dev_idx = 1;
    if (argc > 1) {
        if (strcmp(argv[1], "power") == 0 || strcmp(argv[1], "sleep") == 0) {
            is_power = 1;
            start_dev_idx = 2;
        } else if (strcmp(argv[1], "home") == 0) {
            is_power = 0;
            start_dev_idx = 2;
        }
    }

    if (is_power) {
        // Send KEY_POWER (116) tap to /dev/input/event0
        int fd_p = open("/dev/input/event0", O_WRONLY);
        if (fd_p >= 0) {
            emit(fd_p, EV_KEY, 116, 1);
            emit(fd_p, EV_SYN, SYN_REPORT, 0);
            usleep(20000); // 20ms tap duration
            emit(fd_p, EV_KEY, 116, 0);
            emit(fd_p, EV_SYN, SYN_REPORT, 0);
            close(fd_p);
        }
        // Also send KEY_SLEEP (142) to keyboard devices
        if (argc > start_dev_idx) {
            for (int i = start_dev_idx; i < argc; i++) {
                int fd = open(argv[i], O_WRONLY);
                if (fd < 0) continue;
                emit(fd, EV_KEY, 142, 1);
                emit(fd, EV_SYN, SYN_REPORT, 0);
                emit(fd, EV_KEY, 142, 0);
                emit(fd, EV_SYN, SYN_REPORT, 0);
                close(fd);
            }
        } else {
            const char *devs[] = {"/dev/input/event12", "/dev/input/event14", "/dev/input/event0"};
            for (int i = 0; i < 3; i++) {
                int fd = open(devs[i], O_WRONLY);
                if (fd >= 0) {
                    emit(fd, EV_KEY, 142, 1);
                    emit(fd, EV_SYN, SYN_REPORT, 0);
                    emit(fd, EV_KEY, 142, 0);
                    emit(fd, EV_SYN, SYN_REPORT, 0);
                    close(fd);
                }
            }
        }
    } else {
        // HOME: send KEY_HOME (102) to keyboard devices
        if (argc > start_dev_idx) {
            for (int i = start_dev_idx; i < argc; i++) {
                int fd = open(argv[i], O_WRONLY);
                if (fd < 0) continue;
                emit(fd, EV_KEY, 102, 1);
                emit(fd, EV_SYN, SYN_REPORT, 0);
                emit(fd, EV_KEY, 102, 0);
                emit(fd, EV_SYN, SYN_REPORT, 0);
                close(fd);
            }
        } else {
            const char *devs[] = {"/dev/input/event12", "/dev/input/event14", "/dev/input/event0"};
            for (int i = 0; i < 3; i++) {
                int fd = open(devs[i], O_WRONLY);
                if (fd >= 0) {
                    emit(fd, EV_KEY, 102, 1);
                    emit(fd, EV_SYN, SYN_REPORT, 0);
                    emit(fd, EV_KEY, 102, 0);
                    emit(fd, EV_SYN, SYN_REPORT, 0);
                    close(fd);
                }
            }
        }
    }
    return 0;
}

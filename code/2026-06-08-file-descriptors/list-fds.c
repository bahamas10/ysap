#include <stdio.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/resource.h>

bool fd_valid(int fd) {
	int flags = fcntl(fd, F_GETFD);
	return flags != -1;
}

int main() {
	struct rlimit rl;

	getrlimit(RLIMIT_NOFILE, &rl);

	printf("soft=%u hard=%u\n", rl.rlim_cur, rl.rlim_max);

	for (int i = 0; i < rl.rlim_max; i++) {
		if (fd_valid(i)) {
			printf("fd %d: open\n", i);
		}
	}

	return 0;
}

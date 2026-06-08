#include <stdio.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdlib.h>

bool fd_valid(int fd) {
	int flags = fcntl(fd, F_GETFD);
	return flags != -1;
}

int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "Usage: check-fd <number>\n");
		return 1;
	}

	int fd = atoi(argv[1]);

	printf("fd %d: ", fd);
	if (fd_valid(fd)) {
		printf("open\n");
	} else {
		printf("closed\n");
	}

	return 0;
}

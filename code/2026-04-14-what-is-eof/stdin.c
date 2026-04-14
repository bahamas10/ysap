#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

int main() {
	// just use the already-open stdin fd
	int fd = 0;

	// read the file
	while (true) {
		char buf[1];
		ssize_t n = read(fd, buf, 1);
		if (n == -1) {
			printf("error reading from file\n");
			break;
		} else if (n == 0) {
			printf("nothing left to read (EOF)\n");
			break;
		}

		// n > 0
		char c = buf[0];
		printf("read %zd bytes: '%c'\n", n, c);
	}

	close(fd);

	return 0;
}

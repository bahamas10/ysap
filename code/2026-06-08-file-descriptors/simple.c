#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main() {
	int fd = open("/dev/full", O_WRONLY | O_CREAT | O_TRUNC, 0644);

	if (fd == -1) {
		perror("open");
		return 1;
	}

	pause();

	printf("fd = %d\n", fd);

	// write to the file
	char buf[] = "hello world\n";
	size_t count = sizeof (buf) - 1;

	ssize_t n = write(fd, buf, count);

	if (n != count) {
		perror("write");
		return 42;
	}

	close(fd);

	return 0;
}

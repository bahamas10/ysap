#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
	int fd = open("file.txt", O_CREAT | O_WRONLY | O_APPEND, 0644);
	dup2(fd, 1);
	close(fd);

	printf("Hello World\n");

	return 0;
}

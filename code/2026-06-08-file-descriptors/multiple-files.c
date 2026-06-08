#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
	int fd1 = open("file.txt", O_RDWR | O_CREAT | O_APPEND, 0644);
	int fd2 = dup2(fd1, 67);

	printf("fd1 = %d\n", fd1);
	printf("fd2 = %d\n", fd2);

	write(fd1, "foo\n", 4);
	write(fd2, "bar\n", 4);

	close(fd1);
	close(fd2);

	return 0;
}

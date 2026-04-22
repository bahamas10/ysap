#include <stdio.h>
#include <unistd.h>

int main() {
	pid_t pid = fork();

	if (pid < 0) {
		// fork failed
		return 1;
	}

	if (pid > 0) {
		// we are the parent - pause here and ignore
		// our child
		printf("creating zombie with pid: %d\n", pid);
		while (1) {
			pause();
		}
	} else {
		// we are the child - just die
		return 0;
	}
}

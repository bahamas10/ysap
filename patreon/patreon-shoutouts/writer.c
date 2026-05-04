#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

int main(int argc, char **argv) {
	char c;
	ssize_t n;

	// optionally take sleep time as arg1
	useconds_t sleep_time = 0;
	if (argc >= 2) {
		sleep_time = atoi(argv[1]);
	}
	if (sleep_time == 0) {
		sleep_time = 18 * 1000;
	}

	while ((n = read(0, &c, 1)) > 0) {
		if (c == 0x1b || c == ' ' || c == '\n') {
			// do nothing
		} else {
			usleep(sleep_time);
		}

		// TODO: error checking
		write(1, &c, 1);
	}

	return 0;
}

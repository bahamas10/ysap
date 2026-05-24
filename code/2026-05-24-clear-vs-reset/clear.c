#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main() {
	// HARDCODED ANSI - won't support other terminals
	const char *s = "\e[H\e[2J\e[3J";
	ssize_t len = strlen(s);

	ssize_t n = write(STDOUT_FILENO, s, len);

	return len == n ? EXIT_SUCCESS : EXIT_FAILURE;
}

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

int main() {
	// THIS ONLY MAKES SENSE FOR DAVES TERMINAL
	int fd = open("/dev/tty", O_RDONLY);
	if (fd < 0) {
		return EXIT_FAILURE;
	}

	// get our current terminal attrs
	struct termios t;
	if (tcgetattr(fd, &t) == -1) {
		return EXIT_FAILURE;
	}

	/* input modes */
	t.c_iflag |= BRKINT | ICRNL | IXON;
	t.c_iflag &= ~(IGNBRK | INLCR | IGNCR | ISTRIP);

	/* output modes */
	// try adding 'OLCUC' lol
	t.c_oflag |= OPOST | ONLCR;

	/* control modes */
	t.c_cflag |= CREAD | CS8;
	t.c_cflag &= ~(PARENB);

	/* local modes */
	t.c_lflag |= ECHO | ECHOE | ECHOK | ICANON | ISIG | IEXTEN;
	t.c_lflag &= ~(NOFLSH | TOSTOP);

	/* special characters */
	t.c_cc[VEOF]  = 4;    /* Ctrl-D */
	t.c_cc[VERASE] = 127; /* DEL / Backspace-ish */
	t.c_cc[VINTR] = 3;    /* Ctrl-C */
	t.c_cc[VKILL] = 21;   /* Ctrl-U */
	t.c_cc[VQUIT] = 28;   /* Ctrl-\ */
	t.c_cc[VSUSP] = 26;   /* Ctrl-Z */
	t.c_cc[VTIME] = 0;
	t.c_cc[VMIN] = 1;

	// write the attrs back
	if (tcsetattr(fd, TCSANOW, &t) == -1) {
		return EXIT_FAILURE;
	}

	close(fd);

	const char s[] =
		"\033c"        // RIS - Reset to Initial State
		"\033]104\007" // OSC - Reset color palette (modern)
		"\033[!p"      // DECSTR - Soft Terminal Reset
		"\033[?3;4l"   // CSI - Reset DEC private modes (very old)
		"\033[4l"      // CSI - Disable insert mode
		"\033>"        // ESC - Normal Keypad Mode (very old)
		"\033[?69l"    // CSI - Private mode reset (similar to above, old)
		;
	ssize_t len = strlen(s);

	ssize_t n = write(STDERR_FILENO, s, len);

	return len == n ? EXIT_SUCCESS : EXIT_FAILURE;
}

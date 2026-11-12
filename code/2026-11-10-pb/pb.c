/*
 * Simple progress bar inspired by `pv`
 *
 * https://youtu.be/rl8wxVnJcs8
 *
 * # Created
 * Author: Dave Eddy <ysap@daveeddy.com>
 * Date: October 26, 2026
 * License: MIT
 *
 * # Contributors
 * - Dave Eddy <ysap@daveeddy.com>
 */

#include <errno.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

static atomic_bool g_done = false;
static atomic_ullong g_bytes_copied = 0;
static unsigned long long g_bytes_total = 0;
volatile sig_atomic_t g_needs_resize = 0;

static int g_columns = 80;
static int g_input_fd = STDIN_FILENO;
static int g_output_fd = STDOUT_FILENO;

static const char *GREEN = "\e[32m";
static const char *DIM = "\e[2m";
static const char *RST = "\e[0m";

void handle_sigwinch(int sig) {
	g_needs_resize = 1;
}

void get_window_size() {
	struct winsize ws;

	if (ioctl(STDERR_FILENO, TIOCGWINSZ, &ws) == -1) {
		return;
	}

	g_columns = ws.ws_col;
}

enum Number {
	NUM_0 = 0,
	NUM_1,
	NUM_2,
	NUM_3,
	NUM_4,
	NUM_5,
	NUM_6,
	NUM_7,
	NUM_8,
	NUM_9,
	NUM_PERCENT,
	NUM_NONE,
};

void print_big_number(int i) {
	static const char *font[][2] = {
		{"█▀█",
		 "█▄█"},

		{"▀█ ",
		 "▄█▄"},

		{"▀▀█",
		 "██▄"},

		{"▀▀█",
		 "▄██"},

		{"█ █",
		 " ▀█"},

		{"█▀▀",
		 "▄▄█"},

		{"█▀▀",
		 "█▄█"},

		{"▀▀█",
		 " █ "},

		{"█▀█",
		 "███"},

		{"█▀█",
		 "▀▀█"},

		{"▀▄▀",
		 "▀ ▀"},

		{"   ",
		 "   "},
	};
	fprintf(stderr, "%s", font[i][0]);
	fprintf(stderr, "\e[1B\e[3D");
	fprintf(stderr, "%s", font[i][1]);
	fprintf(stderr, "\e[1A\e[1C");
}

static const char *format_bytes(unsigned long long bytes, bool per_second) {
	static char s[256];
	static const char *units[] = { "B", "KiB", "MiB", "GiB", "TiB" };

	int n_units = sizeof (units) / sizeof (units[0]);
	int unit = 0;

	while (bytes > 1024 && unit < n_units) {
		unit++;
		bytes /= 1024;
	}

	if (per_second) {
		snprintf(s, sizeof (s), "%llu %s/s", bytes, units[unit]);
	} else {
		snprintf(s, sizeof (s), "%llu %s", bytes, units[unit]);
	}

	return s;
}

static const char *format_total(unsigned long long total) {
	return format_bytes(total, false);
}

static const char *format_speed(unsigned long long speed) {
	return format_bytes(speed, true);
}

static const char *format_eta(unsigned long long eta) {
	static char s[256];

	unsigned long long minutes = eta / 60;
	unsigned long long seconds = eta % 60;

	snprintf(s, sizeof (s), "%02llu:%02llu", minutes, seconds);

	return s;
}

static void save_cursor() {
	fprintf(stderr, "\e[s");
}

static void restore_cursor() {
	fprintf(stderr, "\e[u");
}

static void *worker_thread(void *arg) {
	unsigned char buf[BUFSIZ];

	while (true) {
		// read some data
		ssize_t n_read = read(g_input_fd, buf, sizeof (buf));
		if (n_read == 0) {
			// done reading
			break;
		} else if (n_read == -1) {
			// error
			if (errno == EINTR) {
				continue;
			}

			perror("read");
			goto done;
		}

		// write some data
		ssize_t offset = 0;
		while (offset < n_read) {
			ssize_t n_write = write(g_output_fd, buf + offset,
			    n_read - offset);

			if (n_write == -1) {
				// error
				if (errno == EINTR) {
					continue;
				}

				perror("write");
				goto done;
			}

			offset += n_write;

			atomic_fetch_add(&g_bytes_copied,
			    (unsigned long long)n_write);
		}
	}

done:
	atomic_store(&g_done, true);
	return NULL;
}

void draw_block_row(unsigned long long pct_copied) {
	const char *block_7_8 = "▉";
	for (int i = 0; i < g_columns - 2; i++) {
		int pct = i * 100 / g_columns;

		if (pct < pct_copied) {
			fprintf(stderr, "%s", GREEN);
		} else {
			fprintf(stderr, "%s", DIM);
		}
		fprintf(stderr, "%s", block_7_8);
		fprintf(stderr, "%s", RST);
	}
}

void print_percent(unsigned long long pct) {
	enum Number hundreds;
	enum Number tens;
	enum Number ones;

	unsigned long long tmp;

	if (pct < 100) {
		hundreds = NUM_NONE;
	} else {
		tmp = pct / 100;
		tmp %= 10;
		hundreds = tmp;
	}

	if (pct < 10) {
		tens = NUM_NONE;
	} else {
		tmp = pct / 10;
		tmp %= 10;
		tens = tmp;
	}

	ones = pct % 10;

	print_big_number(hundreds);
	print_big_number(tens);
	print_big_number(ones);
	print_big_number(NUM_PERCENT);
}

static void render_progress() {
	static unsigned long long prev_copied = 0;

	unsigned long long cur_copied = atomic_load(&g_bytes_copied);
	unsigned long long total = g_bytes_total;

	// note: could overflow
	unsigned long long pct_copied = (cur_copied * 100) / total;

	// calculate speed
	unsigned long long delta = cur_copied - prev_copied;

	// calculate eta
	unsigned long long bytes_left = total - cur_copied;
	unsigned long long eta = bytes_left / delta;

	unsigned long long speed = delta / 1; // 1 == samples per second

	prev_copied = cur_copied;

	// move the cursor and draw the blocks
	restore_cursor();
	fprintf(stderr, "\e[1B\e[1C");
	draw_block_row(pct_copied);

	restore_cursor();
	fprintf(stderr, "\e[2B\e[1C");
	draw_block_row(pct_copied);

	// draw the stats
	restore_cursor();
	fprintf(stderr, "\e[4B");

	int spaces = (g_columns - 3) / 4;

	fprintf(stderr, "%s", GREEN);

	// print percent first
	fprintf(stderr, "\e[1C");
	print_percent(pct_copied);

	fprintf(stderr, "\e[%dC", spaces - 16 - 1 + 2);
	fprintf(stderr, "%-*s", spaces - 2, format_total(cur_copied));

	fprintf(stderr, "\e[3C");
	fprintf(stderr, "%-*s", spaces - 2, format_speed(speed));

	fprintf(stderr, "\e[3C");
	fprintf(stderr, "%-*s", spaces - 2, format_eta(eta));

	fprintf(stderr, "%s", RST);

	restore_cursor();
	fprintf(stderr, "\e[6B");
	fflush(stderr);
}

static void repeat_text(const char *s, int times) {
	for (int i = 0; i < times; i++) {
		fprintf(stderr, "%s", s);
	}
}

static void draw_static_ui() {
	const char *WE = "─";
	const char *NS = "│";
	const char *SE = "┌";
	const char *NE = "└";
	const char *SW = "┐";
	const char *NW = "┘";
	const char *SWE = "┬";
	const char *NWE = "┴";

	restore_cursor();

	fprintf(stderr, "%s", GREEN);

	// open the box (progress bar section)
	fprintf(stderr, "%s", SE);
	repeat_text(WE, g_columns - 2);
	fprintf(stderr, "%s", SW);
	fprintf(stderr, "\n");

	// put empty room in box
	for (int i = 0; i < 2; i++) {
		fprintf(stderr, "%s", NS);
		repeat_text(" ", g_columns - 2);
		fprintf(stderr, "%s", NS);
		fprintf(stderr, "\n");
	}

	// close the box
	fprintf(stderr, "%s", NE);
	repeat_text(WE, g_columns - 2);
	fprintf(stderr, "%s", NW);
	fprintf(stderr, "\n");

	fprintf(stderr, "%s", RST);

	// print the vertical bars (metadata section)
	fprintf(stderr, "%s", DIM);
	int spaces = (g_columns - 3) / 4;
	repeat_text(" ", spaces);
	fprintf(stderr, "%s", NS);
	repeat_text(" ", spaces);
	fprintf(stderr, "%s", NS);
	repeat_text(" ", spaces);
	fprintf(stderr, "%s", NS);
	repeat_text(" ", spaces);
	fprintf(stderr, "\n");

	fprintf(stderr, "%-*s", spaces, "");
	fprintf(stderr, "%s", NS);
	fprintf(stderr, "%-*s", spaces, " total");
	fprintf(stderr, "%s", NS);
	fprintf(stderr, "%-*s", spaces, " speed");
	fprintf(stderr, "%s", NS);
	fprintf(stderr, "%-*s", spaces, " eta");
	fprintf(stderr, "\n");
	fprintf(stderr, "%s", RST);
}

void clear_old_screen() {
	restore_cursor();

	for (int i = 0; i < 6; i++) {
		fprintf(stderr, "\e[2K\e[1B");
	}
	fflush(stderr);
}

int main(int argc, char **argv) {
	pthread_t worker;

	// grab arguments from the user
	int opt;
	while ((opt = getopt(argc, argv, "s:")) != -1) {
		switch (opt) {
		case 's': {
			// size argument
			char *end;
			errno = 0;
			g_bytes_total = strtoull(optarg, &end, 10);
			if (errno != 0 || *end != '\0') {
				fprintf(stderr, "invalid size: %s\n",
				    optarg);
				return EXIT_FAILURE;
			}
			break;
		}
		default:
			fprintf(stderr, "invalid args\n");
			return EXIT_FAILURE;
		}
	}

	if (g_bytes_total == 0) {
		fprintf(stderr, "total size cannot be 0\n");
		return EXIT_FAILURE;
	}

	// start the thread
	int err = pthread_create(&worker, NULL, worker_thread, NULL);
	if (err != 0) {
		errno = err;
		perror("pthread_create");
		return EXIT_FAILURE;
	}

	// thread is running - display the stats until the thread is done
	signal(SIGWINCH, handle_sigwinch);
	get_window_size();

	// make room for our display before saving cursor
	fprintf(stderr, "\n\n\n\n\n\n");
	fflush(stderr);
	fprintf(stderr, "\e[6A");
	save_cursor();
	draw_static_ui();

	while (!atomic_load(&g_done)) {
		if (g_needs_resize) {
			get_window_size();
			g_needs_resize = 0;
			clear_old_screen();
			draw_static_ui();
		}

		render_progress();
		sleep(1);
	}
	render_progress();

	// wait for the thread to finish
	err = pthread_join(worker, NULL);
	if (err != 0) {
		errno = err;
		perror("pthread_join");
		return EXIT_FAILURE;
	}

	//fprintf(stderr, "\n");

	return EXIT_SUCCESS;
}

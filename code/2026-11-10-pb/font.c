/*
 * # Created
 * Author: Dave Eddy <ysap@daveeddy.com>
 * Date: October 26, 2026
 * License: MIT
 *
 * # Contributors
 * - Dave Eddy <ysap@daveeddy.com>
 */

#include <stdio.h>

// ▀ ▄ █
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

void print_number(int i) {
	printf("%s", font[i][0]);
	printf("\e[1B\e[3D");
	printf("%s", font[i][1]);
	printf("\e[1A\e[1C");
}

int main() {
	printf("\n\n");
	printf("\e[2A");

	print_number(NUM_NONE);
	print_number(NUM_NONE);
	print_number(NUM_2);
	print_number(NUM_PERCENT);

	printf("\n\n");

	return 0;
}

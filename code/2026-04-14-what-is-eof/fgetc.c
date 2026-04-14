#include <stdbool.h>
#include <stdio.h>

int main() {
	FILE *fp = fopen("file.txt", "r");

	if (fp == NULL) {
		// todo: better error-checking lol
		return 1;
	}
	// file was opened successfully

	// read the file now
	while (true) {
		// read 1 character
		int c = fgetc(fp);

		printf("read int: '%d'\n", c);

		// stop here if we are done (or an error occurred)
		if (c == EOF) {
			printf("EOF reached - exiting loop\n");
			break;
		}

		// we read 1 character - print it
		//printf("read character: '%c'\n", c);
	}

	fclose(fp);

	return 0;
}

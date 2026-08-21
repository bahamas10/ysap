#include <stdio.h>

int main(int argc, char **argv) {
	printf("got %d arguments\n", argc - 1);

	for (int i = 1; i < argc; i++) {
		printf("arg%d: %s\n", i, argv[i]);
	}

	return 0;
}

#include <stdio.h>

extern char **environ;

int main(int argc, char **argv) {
	while (*environ != NULL) {
		printf("%s\n", *environ);
		environ++;
	}
	return 0;
}

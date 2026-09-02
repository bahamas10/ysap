#include <door.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char** argv) {
	int door = open("./my-file.door", O_RDONLY);
	if (door == -1) {
		perror("open");
		return 1;
	}

	// call the door (this is like calling "door_func" in the server)
	printf("calling door\n");

	char *input = "hi from client";

	door_arg_t args = {0};
	args.data_ptr = input;
	args.data_size = strlen(input) + 1;
	int result = door_call(door, &args);
	if (result == -1) {
		perror("door_call");
		return 1;
	}

	printf("door called successfully\n");
	printf("got data: %s\n", args.data_ptr);

	return 0;
}

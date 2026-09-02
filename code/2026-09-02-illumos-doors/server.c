#include <door.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

void door_func(void *cookie, char *args, size_t nargs,
    door_desc_t* desc, uint_t ndesc) {

	// interrogate our client
	ucred_t *uc = NULL;
	if (door_ucred(&uc) == 0) {
		uid_t euid = ucred_geteuid(uc);
		pid_t pid = ucred_getpid(uc);
		zoneid_t zoneid = ucred_getzoneid(uc);

		printf("client request received from pid %d uid %d zone %d\n",
		    pid, euid, zoneid);

		ucred_free(uc);
	}

	printf("got data from client: %s\n", args);

	char *response = "hello from door_func";
	door_return(response, strlen(response) + 1, NULL, 0);
}

int main() {
	char *path = "./my-file.door";

	// create the file
	unlink(path);
	int fd = open(path, O_RDWR | O_CREAT, 0644);
	if (fd == -1) {
		perror("open");
		return 1;
	}
	close(fd);

	// create the door
	int door = door_create(&door_func, NULL, 0);
	if (door == -1) {
		perror("door_create");
		return 1;
	}

	// attach the door to the file
	if ((fattach(door, path)) == -1) {
		perror("fattach");
		return 1;
	}

	printf("door created: %s\n", path);
	printf("waiting for requests...\n");

	// run forever
	while (1) {
		pause();
	}

	return 0;
}

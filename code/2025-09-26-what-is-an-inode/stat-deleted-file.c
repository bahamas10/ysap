/*
 * call fstat on an open but deleted file to show the link count is, in fact, 0.
 *
 * Author: Dave Eddy <dave@daveeddy.com>
 * Date: September 19, 2025
 * License: MIT
 */

#include <err.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>

int main() {
	// open the temp file (creating it)
	char *file = "this-file-will-be-deleted";
	int fd = open(file, O_RDONLY | O_CREAT);
	if (fd == -1) {
		err(1, "failed to open %s", file);
	}
	printf("opened: %s (fd=%d)\n", file, fd);

	// remove the temp file (while it is opened)
	int ret = unlink(file);
	if (ret == -1) {
		err(1, "failed to unlink %s", file);
	}
	printf("removed: %s\n", file);

	// stat the file descriptor
	struct stat sb;
	if (fstat(fd, &sb) == -1) {
		err(1, "failed to fstat fd %d", fd);
	}
	printf("fstat: %d\n\n", fd);
	printf("size: %d bytes\n", (int)sb.st_size);
        printf("uid: %d\n", sb.st_uid);
        printf("gid: %d\n", sb.st_gid);
        printf("mode: %o\n", sb.st_mode);
        printf("dev: %d\n", (int)sb.st_dev);
        printf("inode: %d\n", (int)sb.st_ino);
        printf("nlinks: %d\n", (int)sb.st_nlink);

	// close the fd (this will happen when the process dies regardless)
	close(fd);

	return 0;
}

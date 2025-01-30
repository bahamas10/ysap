#include <stdlib.h>

int main() {
	system("echo '#!/bin/bash' > script");
	system("echo 'echo hello world' >> script");
	system("chmod 755 script");
	system("./script");
	return 0;
}

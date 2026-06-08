#include <unistd.h>

int main() {
	write(3, "foo\n", 4);
}

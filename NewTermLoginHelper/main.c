//
//  main.c
//  NewTermLoginHelper
//
//  Created by Adam Demasi on 21/7/2022.
//

#include <errno.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
	// Sanity check
	if (argc < 3 || strcmp(argv[0], "-NewTermLoginHelper") != 0) {
		fprintf(stderr, "This helper is used by NewTerm to launch a terminal process, and shouldn’t be run directly.\n");
		return 1;
	}

	// Become a controlling tty. Equivalent to what login_tty() does, according to FreeBSD source.
	if (setsid() != getpid()) {
		perror("setsid()");
	}

	if (ioctl(0, TIOCSCTTY, NULL) != 0) {
		perror("ioctl()");
	}

	// Change cwd to the one passed on the command line.
	chdir(argv[1]);

	// Construct command line to exec by replacing argv[2] with shell basename preceded by "-", which
	// indicates to the shell that it is being launched by login(1).
	char *program = malloc(strlen(argv[2]));
	strcpy(program, argv[2]);
	asprintf(&argv[2], "-%s", basename(program));

	// Now exec the shell, using our supplied command line from argv[2] onwards.
	execvp(program, (char **)&argv[2]);

	// If we got to here, exec failed. Print the error.
	perror(program);
	return 1;
}

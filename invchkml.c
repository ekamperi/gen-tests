#include <err.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function prototypes */
static void usage();

int main(int argc, char *argv[])
{
	char manpage[100], section[2];
	char *s, e*;

	/* Check argument count */
	if (argc != 2)
		usage();

	/* Extract man page name and section number */


	return (EXIT_SUCCESS);
}

static void
usage()
{
	fprintf(stderr, "Usage: %s manpage\n", getprogname());
	exit(EXIT_FAILURE);
}

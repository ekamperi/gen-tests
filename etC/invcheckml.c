#include <err.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAN_PATH "/usr/bin/man"	/* man(1) path */

/* Function prototypes */
static void usage();

int main(int argc, char *argv[])
{
	char buf[100000];
	char cmd[100];
	char manpage[100];
	char section[2];
	char *filename, *last, *token;
	FILE *fp;

	/* Check argument count */
	if (argc != 2)
		usage();

	/* Argh, pointer to internal static buffer */
	filename = basename(argv[1]);

	/* Extract man page name and section number */
	token = strtok_r(filename, ".\n", &last);
	if (token) {
		strlcpy(manpage, token, sizeof(manpage));
		token = strtok_r(NULL, ".\n", &last);
		if (token)
			strlcpy(section, token, sizeof(section));
		else
			errx(EXIT_FAILURE, "not a man page file");
	} else {
		errx(EXIT_FAILURE, "wtf?");
	}

	/* Construct a man(1) invocation */
	snprintf(cmd, sizeof(cmd), "%s %s %s 2>&- | col -b",
	    MAN_PATH, section, manpage);

	/* Open a pipe to man(1) */
	fp = popen(cmd, "r");
	if (fp == NULL) {
		err(EXIT_FAILURE, "popen");
	} else {
		while (fgets(buf, sizeof(buf), fp) != NULL) {
			if (strstr(buf, manpage) != NULL) {
				/* Bingo! */
				goto CLEANUP_AND_EXIT;
			}
		}
	}

	printf("Possibly bogus MLINK to %s(%s)\n", manpage, section);

CLEANUP_AND_EXIT:;
	pclose(fp);
	return (EXIT_SUCCESS);
}

static void
usage()
{
	fprintf(stderr, "Usage: %s manpage\n", getprogname());
	exit(EXIT_FAILURE);
}

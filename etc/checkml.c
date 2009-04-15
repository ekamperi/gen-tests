/*
 * The following code extracts all function names that are mentioned in the
 * SYNOPSIS section of an mdoc file, and for each one of them it calls man(1)
 * to (indirectly) check whether there is an MLINK to them.
 */

#include <ctype.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/queue.h>

#define MANPATH "/usr/bin/man"		/* man(1) path   */
int verbose = 0;			/* verbose level */

/* We keep track of the cross-referenced functions, inside a linked list */
SLIST_HEAD(slisthead, m_entry) head =
    SLIST_HEAD_INITIALIZER(head);
struct m_entry {
	char m_fname[100];		/* function name */
	SLIST_ENTRY(m_entry) m_entries;
};

/* Function prototypes */
static int parseline(char *line);
static void usage(void);

int main(int argc, char *argv[])
{
	char cmd[1000], line[1000];
	bool syn;
	FILE *fp;

	/* Check argument count */
	if (argc != 2)
		usage();

	/* Open file */
	fp = fopen(argv[1], "r");
	if (fp == NULL)
		err(EXIT_FAILURE, "fopen");

	/* Parse file and extract function cross references */
	syn = 0;
	SLIST_INIT(&head);

	while(!feof(fp)) {
		if (fgets(line, sizeof(line), fp) == NULL) {
			if (!feof(fp)) {
				fclose(fp);
				err(EXIT_FAILURE, "fread");
			}
		} else {
			if (strstr(line, ".Sh SYNOPSIS") != NULL) {
				syn = 1;
				continue;
			}

			if (syn == 1 && strstr(line, ".Sh") != NULL)
				break;

			if (syn == 1) {
				/*
				 * We are inside the SYNOPSIS section the man
				 * page, which is the only part of the file we
				 * care about anyway.
				 */
				parseline(line);
			}
		}
	}

	/*
	 * For every function referenced in the manpage, check if there is
	 * an MLINK to it. We do so, by issuing a specially crafted man(1)
	 * invocation and then checking its return code. Mind that system(3)
	 * invokes the /bin/sh shell.
	 */
	struct m_entry *mp;
	int ret;
	SLIST_FOREACH(mp, &head, m_entries) {
		/* Construct command */
                snprintf(cmd, sizeof(cmd), "%s -w %s 1>&- 2>&-",
		    MANPATH, mp->m_fname);
		if (verbose)
			printf("Executing command: %s\n", cmd);

		/* Run it */
		ret = system(cmd);
		if (ret == -1)
			warnx("system");
		else if (ret == 127)
			warnx("execution of shell failed");
		else if (ret != 0)
			printf("Possibly missing MLINK for %s (%s)\n",
			    mp->m_fname, argv[1]);

		/* We don't need the function node any more */
		SLIST_REMOVE(&head, mp, m_entry, m_entries);
		free(mp);
	}

	fclose(fp);
	return (EXIT_SUCCESS);
}

#define VALID_FUNCTION(x) ((*x) != '*' && (*x) != '\\' && (*x) != '(')

static int
parseline(char *line)
{
	struct m_entry *mp;
	char *token, *last;

	token = strtok_r(line, " \n", &last);
	if (token) {
		if ((strcmp(token, ".Fn") == 0) ||
		    (strcmp(token, ".Fo") == 0)) {
			/*
			 * We found a function reference. The second token after
			 * an .Fn or .Fo macro, is the function name itself. The
			 * precise syntax is: .Fn <function> [<parameters>]
			 */
			token = strtok_r(NULL, " \n", &last);
			if (token && VALID_FUNCTION(token)) {
				mp = malloc(sizeof(*mp));
				strncpy(mp->m_fname, token, sizeof(mp->m_fname));
				SLIST_INSERT_HEAD(&head, mp, m_entries);
				return (0);
			}
		}
	}

	/* No function reference */
	return (-1);
}

static void
usage(void)
{
	fprintf(stderr, "%s mdocfile\n", getprogname());
	exit(EXIT_FAILURE);
}

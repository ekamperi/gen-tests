#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>	/* for memset() */
#include <unistd.h>
#include <linux/limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/inotify.h>

/* Function prototypes. */
static void diep(const char *s);

int main(int argc, char *argv[])
{
	/* 64 simultaneous events at most. */
	char buf[(sizeof(struct inotify_event) + FILENAME_MAX) << 6];
	struct inotify_event *pevt;
	int fd, wd;
	ssize_t i, bytes;
	char *p;

	/* Check argument count. */
	if (argc != 2) {
		fprintf(stderr, "Usage: %s directory\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	/* Initialize inotify. */
	fd = inotify_init();
	if (fd == -1)
		diep("inotify_init");

	/* Add watch. */
	wd = inotify_add_watch(fd, argv[1], IN_CREATE);
	if (wd == -1)
		diep("inotify_add_watch");

	/* Loop forever. */
	for (;;) {
		memset(buf, 0, sizeof(buf));
		bytes = read(fd, buf, sizeof(buf));

		/* Handle occured events. */
		i = 0;
		do {
			pevt = (struct inotify_event *)&buf[i];

			/* Sanity check. */
			assert((pevt->mask & IN_CREATE) == IN_CREATE);

			/* Make sure newly created file doesn't end with .php~ */
			if ((p = strstr(pevt->name, ".php~"))) {
				if (p[5] == '\0')
					fprintf(stderr, "Warning: %s has a "
					    ".php~ extension.\n", pevt->name);

				/* Delete the offending file. */
				char path[PATH_MAX + 1];

				memset(path, 0, PATH_MAX);
				strncpy(path, argv[1], PATH_MAX);
				strncat(path, "/", PATH_MAX);
				strncat(path, pevt->name, PATH_MAX);

				if (unlink(path) == -1) {
					/* XXX: Handle at least EBUSY. */
					diep("unlink");
				}

				fprintf(stderr, "Info: %s was deleted\n",
				    pevt->name);
			}

			/* Advance offset. */
			i += sizeof(struct inotify_event) + pevt->len;
		} while (i < bytes);
	}


	return (EXIT_SUCCESS);
}

static void
diep(const char *s)
{
	perror(s);
	exit(EXIT_FAILURE);
}

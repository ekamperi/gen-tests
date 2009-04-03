#include <err.h>
#include <stdio.h>
#include <sys/types.h>
#include <libutil.h>

struct hentry {
	const char *h_str;
	int64_t h_res;
} htable[] = {
	{ "1",  1         },
	{ "1b", 1         },
	{ "1k", 1   << 10 },	/* 1024			*/
	{ "1M", 1   << 20 },	/* 1048576		*/
	{ "1G", 1   << 30 },	/* 1073741824		*/
	{ "1T", 1LL << 40 },	/* 1099511627776	*/
	{ "1P", 1LL << 50 },	/* 1125899906842624	*/
	{ "1E", 1LL << 60 },	/* 1152921504606846976	*/
	/* expected failures */
	{ "",   -1        },
	{ "1a", -1        },
	{ "1 k",-1        },
	{ "aa", -1        },
	{ "9E", -1        },
	{ NULL, -1        },
};

int main(void)
{
	const struct hentry *he;
	int64_t res;
	int rv;

	for (he = htable; he; he++) {
		if (he->h_str == NULL && he->h_res == -1)
			break;

		rv = dehumanize_number(he->h_str, &res);
		if (rv == -1) {
			/* unexpected failure */
			if (he->h_res != -1)
				warn("%s", he->h_str);
		}
		else {
			/* unexpected result */
			if (res != he->h_res)
				warnx("mismatch: res=%lld\th_res=%lld",
				    res, he->h_res);
		}
	}

	return 0;
}

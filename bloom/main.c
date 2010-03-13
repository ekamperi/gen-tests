#include <assert.h>
#include <limits.h>
#include <pthread.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "bloom.h"

#define NSTRINGS	 1000
#define STRINGSIZE	     20

size_t
hash1(const void *obj)
{
	const char *str = obj;
	size_t hash = 5381;
	int c;

	while ((c = *str++) != 0)
		hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

	return (hash);
}

size_t
hash2(const void *obj)
{
	const char *str = obj;
	unsigned long hash = 0;
	int c;

	while ((c = *str++) != 0)
		hash = c + (hash << 6) + (hash << 16) - hash;

	return (hash);
}

static void *
querythread(void *arg)
{
        char buf[NSTRINGS][STRINGSIZE];

	/* Do NOT be tempted to dereference the bloom pointer */
	bloom_t *p = arg;

	printf("[%p] Generating random strings\n", pthread_self());
	fflush(NULL);

        size_t i, j;
        for (i = 0; i < NSTRINGS; i++) {
		/* Zero out buffer. */
		memset(buf[i], 0, STRINGSIZE);
		for (j = 0; j < 1 + rand() % (STRINGSIZE-1); j++) {
			buf[i][j] = 'a' + rand() % ('z' - 'a');
		}
		/* printf("%s\n", buf[i]); */
	}

        printf("[%p] Populating bloom filter\n", pthread_self());
        fflush(NULL);
	for (i = 0; i < NSTRINGS; i++) {
		bloom_add(p, buf[i]);
	}

        printf("[%p] Querying bloom filter\n", pthread_self());
        fflush(NULL);
	for (i = 0; i < 100; i++) {
		for (j = 0; j < NSTRINGS; j++)
			assert(bloom_query(p, buf[j]));
	}

	pthread_exit(NULL);
}

static void
diep(const char *s)
{
	perror(s);
	exit(EXIT_FAILURE);
}

int
main(void)
{
#define NTHREADS 10
	bloom_t b;

        /* Initialize random number generator. */
        srand(time(NULL));

	/* Initialize the bloom filter */
	size_t (*h[])(const void *obj) = { hash1, hash2 };
	bloom_init(&b, 100000, h, 2);

	/* Create the threads */
	pthread_t tid[NTHREADS];
	int i, rv;

	for (i = 0; i < NTHREADS; i++) {
		rv = pthread_create(&tid[i], NULL, querythread, &b);
		if (rv != 0)
			diep("pthread_create()");
	}

	/* Wait for threads to complete */
	for (i = 0; i < NTHREADS; i++) {
		rv = pthread_join(tid[i], NULL);
		if (rv != 0)
			diep("pthread_join()");
	}

	/* Print some usage statistics */
	printf("usedbits = %u\n", bloom_get_usedbits(&b));
	printf("maxbits = %u\n", bloom_get_maxbits(&b));

	bloom_fini(&b);

	return (EXIT_SUCCESS);
}

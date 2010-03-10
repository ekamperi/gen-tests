#include <assert.h>
#include <limits.h>
#include <pthread.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct bloom {
	char *bl_bitarray;

	size_t (**bl_hashf)(const void *obj);
	size_t bl_nhashf;

	size_t bl_maxbits;

	pthread_rwlock_t bl_rwlock;
} bloom_t;

#define BLOOM_SPOT_BIT(bit, index, offset)		\
	do {						\
		index  = bit / CHAR_BIT;		\
		offset = bit - CHAR_BIT * index;	\
	} while(0)

#define NSTRINGS	 100000
#define STRINGSIZE	     20

/* -------------------------------------------------------------------------- */

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

/* -------------------------------------------------------------------------- */

int
bloom_init(bloom_t *p, size_t maxbits,
    size_t (*hashf[])(const void *obj), size_t nhashf)
{
	assert(p);

	/* Validate input */
	if (nhashf == 0)
		return (-1);

	/* Allocate memory for the bits array */
	p->bl_bitarray = malloc(1 + (maxbits / CHAR_BIT));
	if (p->bl_bitarray == NULL)
		return (-1);

	/* Allocate memory for the hash function vector */
	p->bl_hashf = malloc(nhashf * sizeof(*p->bl_hashf));
	if (p->bl_hashf == NULL) {
		free(p->bl_bitarray);
		return(-1);
	}

	/* Setup the hash function vector */
	size_t i;
	for (i = 0; i < nhashf; i++) {
		assert(hashf[i]);
		p->bl_hashf[i] = hashf[i];
	}

	p->bl_nhashf = nhashf;
	p->bl_maxbits = maxbits;

	/* Initialize readers-writer lock */
	pthread_rwlock_init(&p->bl_rwlock, NULL);

	/* Success */
	return (0);
}

void
bloom_fini(bloom_t *p)
{
	assert(p);

	pthread_rwlock_destroy(&p->bl_rwlock);
	free(p->bl_bitarray);
	free(p->bl_hashf);

	p = NULL;
}

void
bloom_add(bloom_t *p, const void *obj)
{
	assert(p);
	assert(obj);

	size_t bit, i, idx, ofs;
	for (i = 0; i < p->bl_nhashf; i++) {
		bit = (*p->bl_hashf[i])(obj) % p->bl_maxbits;

		BLOOM_SPOT_BIT(bit, idx, ofs);

		pthread_rwlock_wrlock(&p->bl_rwlock);
		p->bl_bitarray[idx] |= (1 << ofs);
		pthread_rwlock_unlock(&p->bl_rwlock);
	}
}

int
bloom_query(bloom_t *p, const void *obj)
{
	assert(p);
	assert(obj);

	size_t bit, i, idx, ofs;
	for (i = 0; i < p->bl_nhashf; i++) {
		bit = (*p->bl_hashf[i])(obj) % p->bl_maxbits;

		BLOOM_SPOT_BIT(bit, idx, ofs);

		pthread_rwlock_rdlock(&p->bl_rwlock);
		int rv = p->bl_bitarray[idx] & (1 << ofs);
		pthread_rwlock_unlock(&p->bl_rwlock);

		if (rv == 0) {
			/* Object does NOT belong to set */
			return (0);
		}
	}

	/* All hash functions agree that object belongs to set */
	return (1);
}

static void
bloom_print_hashf(const bloom_t *p)
{
	assert(p);

	printf("--- List of hash functions ---\n");

	size_t i;
	for (i = 0; i < p->bl_nhashf; i++)
		printf("%p\n", p->bl_hashf[i]);
}

size_t
bloom_get_usedbits(const bloom_t *p)
{
	size_t bit, idx, ofs, usedbits;

	usedbits = 0;
	for (bit = 0; bit < p->bl_maxbits; bit++) {
		BLOOM_SPOT_BIT(bit, idx, ofs);
		if (p->bl_bitarray[idx] & (1 << ofs))
			usedbits++;
	}

	return (usedbits);
}

size_t
bloom_get_maxbits(const bloom_t *p)
{
	return (p->bl_maxbits);
}

static void *
querythread(void *arg)
{
        char buf[NSTRINGS][STRINGSIZE];

	/* Do NOT be tempted to dereference the bloom pointer */
	bloom_t *p = arg;

        size_t i, j;
        for (i = 0; i < NSTRINGS; i++) {
		/* Zero out buffer. */
		memset(buf[i], 0, STRINGSIZE);
		for (j = 0; j < 1 + rand() % (STRINGSIZE-1); j++) {
			buf[i][j] = 'a' + rand() % ('z' - 'a');
		}
		/* printf("%s\n", buf[i]); */
	}

	for (i = 0; i < NSTRINGS; i++) {
		bloom_add(p, buf[i]);
	}

	for (i = 0; i < 1000; i++) {
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
	bloom_t b;

        /* Initialize random number generator. */
        srand(time(NULL));

	/* Create the bloom filter */
	size_t (*h[])(const void *obj) = { hash1, hash2 };

	if (bloom_init(&b, 10000000, h, 2) == -1)
		exit(1);

	bloom_print_hashf(&b);

	/* Create the threads */
#define NTHREADS 10

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

	/* We are done -- cleanup */
	bloom_fini(&b);

	return (EXIT_SUCCESS);
}


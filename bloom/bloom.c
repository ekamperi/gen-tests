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

#define BLOOM_BIT_SPOT(bit, index, offset)		\
	do {						\
		index  = bit / CHAR_BIT;		\
		offset = bit - CHAR_BIT * index;	\
	} while(0)

#define BLOOM_BIT_GET(p, index, offset)			\
	(p)->bl_bitarray[index] & (1 << offset)

#define BLOOM_BIT_SET(p, index, offset)			\
	(p)->bl_bitarray[index] |= (1 << offset)

#define BLOOM_BIT_UNSET(p, index, offset)		\
	(p)->bl_bitarray[index] &= ~(1 << offset)

typedef enum {
	BLOOM_UNION		= 1,
	BLOOM_INTERSECTION	= 2
} bloom_operation_t;

int
bloom_init(bloom_t *p, size_t maxbits,
    size_t (*hashf[])(const void *obj), size_t nhashf)
{
	assert(p);
	assert(hashf);
	assert(nhashf > 0);

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

		BLOOM_BIT_SPOT(bit, idx, ofs);

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

		BLOOM_BIT_SPOT(bit, idx, ofs);

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

void
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

static int
bloom_common(const bloom_t *p1, const bloom_t *p2, bloom_t *u,
    bloom_operation_t operation)
{
	assert(p1);
	assert(p2);

	/* The size of two bloom filters must be the same */
	if (p1->bl_maxbits != p2->bl_maxbits)
		return (-1);

	/* The number of hashing functions must be the same */
	if (p1->bl_nhashf != p2->bl_nhashf)
		return (-1);

	/* Hash functions must be the same */
	size_t i;
	for (i = 0; i < p1->bl_nhashf; i++) {
		if (p1->bl_hashf[i] != p2->bl_hashf[i]) {
			fprintf(stderr,
			    "WARNING: Hashing functionsd may differ. "
			    "Proceeding, but results may be spurious\n.");
			break;
		}
	}


	char byte;
	int rv;
	for (byte = 0; byte < (1 + (maxbits / CHAR_BIT); byte++) {
		/* Find the position of the bit in the array */
                BLOOM_SPOT_BIT(bit, idx, ofs);

		bit1 = BLOOM_GET_BIT(p1, idx, ofs);
		bit2 = BLOOM_GET_BIT(p2, idx, ofs);

		if (operation == BLOOM_UNION) {
			rv = bit1 | bit2;
			if (rv)
				BLOOM_BIT_SET(u, idx, ofs);
			else
				BLOOM_BIT_UNSET(u, idx, ofs);
		} else if (operation == BLOOM_INTERSECTION) {
			rv = bit1 & bit2;
			if (rv)
				BLOOM_BIT_SET(u, idx, ofs);
			else
				BLOOM_BIT_UNSET(u, idx, ofs);
		} else {
			/* Unknown operation */
			return (-1);
		}
	}

	return (0);
}

int
bloom_unite(const bloom_t *p1, const bloom_t *p2, bloom_t *u)
{
	bloom_common(p1, p2, u, BLOOM_UNION);
}

int
bloom_intersect(const bloom_t *p1, const bloom_t *p2, bloom_t *i)
{
	bloom_common(p1, p2, i, BLOOM_INTERSECTION);

	return (0);
}


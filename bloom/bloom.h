#ifndef __BLOOM_H_
#define __BLOOM_H_

typedef struct bloom {
	char *bl_bitarray;
	size_t (**bl_hashf)(const void *obj);
	size_t bl_nhashf;
        size_t bl_maxbits;
        pthread_rwlock_t bl_rwlock;
} bloom_t;

/* Function prototypes */
int
bloom_init(bloom_t *p, size_t maxbits,
	   size_t (*hashf[])(const void *obj), size_t nhashf);
void bloom_fini(bloom_t *p);
void bloom_add(bloom_t *p, const void *obj);
int bloom_query(bloom_t *p, const void *obj);
size_t bloom_get_usedbits(const bloom_t *p);
size_t bloom_get_usedbits(const bloom_t *p);
size_t bloom_get_maxbits(const bloom_t *p);
void bloom_print_hashf(const bloom_t *p);

int bloom_unite(const bloom_t *p1, const bloom_t *p2, bloom_t *u);
int bloom_intersect(const bloom_t *p1, const bloom_t *p2, bloom_t *i);

#endif	/* __BLOOM_H_ */

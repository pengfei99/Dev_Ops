/* seqlist.h - Sequence id list manipulation */

#ifndef __SEQLIST_H_
#define __SEQLIST_H_

typedef struct {
  long num;
  char **lst; } seqlist_t;

void seqlist_init(seqlist_t *);
void seqlist_fini(seqlist_t *);
void seqlist_sort(seqlist_t *);

int seqlist_add(seqlist_t *, char *);
int seqlist_del(seqlist_t *, char *);
int seqlist_chk(seqlist_t *, char *);

#endif /* __SEQLIST_H_ */

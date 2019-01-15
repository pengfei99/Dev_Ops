/* seqlist.c - Sequence id list manipulation */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "seqlist.h"


static int seqlist_compare(const void *a, const void *b) {
  return strcmp(*(char **)a, *(char **)b); }


void seqlist_init(seqlist_t *lst) {

  lst->num = 0;
  lst->lst = NULL;

  return; }

void seqlist_fini(seqlist_t *lst) {
  char **p;

  p = lst->lst;
  while (lst->num--) {
    free(*p++); }

  free(lst->lst);

  return; }


void seqlist_sort(seqlist_t *lst) {

  qsort(lst->lst, lst->num, sizeof(*lst->lst), seqlist_compare);

  return; }


int seqlist_add(seqlist_t *lst, char *key) {
  char **buf;

  if (lst->num % 100 == 0) {
    buf = realloc(lst->lst, (lst->num + 100) * sizeof(*lst->lst));
    if (buf == NULL)
      err(1, "realloc failed");
    lst->lst = buf; }

  *(lst->lst + lst->num) = key;
  lst->num++;

  return 0; }


int seqlist_del(seqlist_t *lst, char *key) {

  return 0; }


int seqlist_chk(seqlist_t *lst, char *key) {
  char **p;
  int i = -1;
  long beg, cur, end;

  beg = 0; end = lst->num - 1;
  while (beg <= end) {
    cur = (beg + end) / 2;

    p = lst->lst + cur;
    i = strcmp(key, *p);

    if (i == 0) { break; }
    if (i < 0) { end = cur - 1; }
    if (i > 0) { beg = cur + 1; }

  }

  return i != 0; }



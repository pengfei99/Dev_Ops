/* fqextract.c - Extract entries from a FASTQ sequence file */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <ctype.h>
#include <err.h>
#include <fcntl.h>
#include <libgen.h>
#include <stdio.h>
#ifdef HAVE_STDLIB_H
# include <stdlib.h>
#endif
#include <string.h>
#include <unistd.h>

#include "seqlist.h"

#ifndef HAVE_STRNDUP
char *strndup(const char *str, size_t len) {
  char *buf;
  size_t siz;

  siz = strlen(str);

  buf = malloc(len + 1);
  if (buf == NULL) { return NULL; }

  memcpy(buf, str, siz > len ? len : siz);
  *(buf+len) = '\0';

  return buf;
}
#endif

static void usage(char *);
static size_t namlen(char *, int);

int main(int argc, char **argv) {
  FILE *f;
  char *buf, *file, *list, *prog;
  int i, n, s, keep, pair, excl;
  size_t len;
  seqlist_t lst;

  /* Inits */
  prog = *argv;
  list = NULL;
  pair = 1;
  excl = 0;

  /* Check command line */
  while ((i = getopt(argc, argv, "hl:px")) != -1) {
    switch (i) {
    case 'h':
      usage(prog); return EXIT_SUCCESS;
    case 'l':
      list = optarg; break;
    case 'p':
      pair = 0; break;
    case 'x':
      excl = 1; break;
    default:
      usage(prog); return EXIT_FAILURE; }
  }
  if (argc - optind < 1) {
    usage(prog); return EXIT_FAILURE; }

  len = 1024;
  if ((buf = malloc(len)) == NULL)
    err(EXIT_FAILURE, "memory: malloc failed");

  /* Load provided entries list */
  if (list != NULL) {
    seqlist_init(&lst);
    if ((f = fopen(list, "r")) == NULL)
      err(EXIT_FAILURE, "%s: open failed", list);
    while (fgets(buf, (int)len, f) != NULL) {
      char *xxx = strndup(buf, namlen(buf, pair));
      seqlist_add(&lst, xxx); }
    if (fclose(f) == EOF)
      err(EXIT_FAILURE, "%s: close failed", list);
    seqlist_sort(&lst); }

  /* Process all sequence files */
  for (i = optind; i < argc; i++) {
    file = *(argv+i);

    if ((f = fopen(file, "r")) == NULL)
      err(EXIT_FAILURE, "%s: open failed", file);

    n = 0; s = 0; keep = 0;
    while (fgets(buf, (int)len, f) != NULL) {

      if (*buf == '\n' && s == 0) continue;
      if (*buf == '@' && s == 0 && n == 0) { n = 4; keep = 1; }

      switch (n) {
      case 4:        /* sequence name */
	if (s == 0 && *buf != '@')
	  errx(EXIT_FAILURE, "sequence: bad header line");
	if (list == NULL || s > 0) break;
	{
	  char *xxx = strndup(buf+1, namlen(buf+1, pair));
	  keep = 1 - seqlist_chk(&lst, xxx);
	  if (excl == 1) { keep = 1 - keep; }
	  free(xxx);
	}
	break;
      case 3: break; /* sequence string */
      case 2:        /* quality name */
	if (s == 0 && *buf != '+')
	  errx(EXIT_FAILURE, "quality: bad header line");
	break;
      case 1: break; /* quality string */
      default:
	errx(EXIT_FAILURE, "%s: invalid format", file); }

      if (keep == 1)
	(void)fprintf(stdout, "%s", buf);
      if (strrchr(buf, '\n') == NULL) { s++; continue; }
      n--; s = 0; }

    if (fclose(f) == EOF)
      err(EXIT_FAILURE, "%s: close failed", file);

  }

  if (list != NULL)
    seqlist_fini(&lst);

  free(buf);

  return 0; }


static void usage(char *prog) {
  FILE *f = stderr;

  (void)fprintf(f, "usage: %s [options] <file> ...\n", basename(prog));
  (void)fprintf(f, "\noptions:\n");
  (void)fprintf(f, "  -h        ... Print this message and exit.\n");
  (void)fprintf(f, "  -l <list> ... Select entries listed in <list>.\n");
  (void)fprintf(f, "  -p        ... Do not use pair member information.\n");
  (void)fprintf(f, "  -x        ... Exclude entries listed in <list>.\n");

  return; }

static size_t namlen(char *nam, int pair) {
  char *p;
  size_t len;

  if ((p = strpbrk(nam, " \n")) == NULL)
    errx(EXIT_FAILURE, "sequence: name too long");
  len = p - nam;

  if (pair == 1)
    return len;

  p = nam + len;
  if (p - nam > 2 && *(p-2) == '/' && isdigit((unsigned char)*(p-1)))
    len -= 2;

  return len; }

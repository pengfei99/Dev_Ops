/* fastq.c - FASTQ sequence file functions */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <assert.h>
#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "fastq.h"


int fastq_init(sequence_t *seq) {

  seq->lnam = 0; seq->snam = NULL;
  seq->lseq = 0; seq->sseq = NULL;
  seq->lqua = 0; seq->squa = NULL;

  return 0; }


int fastq_fini(sequence_t *seq) {

  free(seq->snam);
  free(seq->sseq);
  free(seq->squa);

  return 0; }


int fastq_read(FILE *f, sequence_t *seq) {
  char buf[1024];
  int n, s;
  size_t len;

  s = 0;
  while (fgets(buf, (int)sizeof(buf), f) != NULL) {

    if (*buf == '\n' && s == 0) continue;
    if (*buf == '@' && s == 0) { n = 4; }
    len = strlen(buf);

    switch (n) {
    case 4:        /* sequence name */
      if (s == 0 && *buf != '@')
	errx(EXIT_FAILURE, "sequence: bad header line");
      if (seq->lnam < len) {
	seq->lnam += len;
	seq->snam = realloc(seq->snam, seq->lnam);
	if (seq->snam == NULL)
	  err(EXIT_FAILURE, "malloc failed"); }
      if (s == 0) { *seq->snam = '\0'; }
      (void)strncat(seq->snam, buf + 1, len - 1 - 1);
      break;
    case 3:        /* sequence string */
      if (seq->lseq < len) {
	seq->lseq += len;
	seq->sseq = realloc(seq->sseq, seq->lseq);
	if (seq->sseq == NULL)
	  err(EXIT_FAILURE, "malloc failed"); }
      if (s == 0) { *seq->sseq = '\0'; }
      (void)strncat(seq->sseq, buf, len - 1);
      break;
    case 2:        /* quality name */
      if (s == 0 && *buf != '+')
	errx(EXIT_FAILURE, "quality: bad header line");
      break;
    case 1:        /* quality string */
      if (seq->lqua < len) {
	seq->lqua += len;
	seq->squa = realloc(seq->squa, seq->lqua);
	if (seq->squa == NULL)
	  err(EXIT_FAILURE, "malloc failed"); }
      if (s == 0) { *seq->squa = '\0'; }
      (void)strncat(seq->squa, buf, len - 1);
      break;
    default:
      errx(EXIT_FAILURE, "fastq: invalid format"); }

    if (strrchr(buf, '\n') == NULL) { s++; continue; }
    n--; s = 0;
    if (n == 0) break; }

  return 0; }


int fastq_write(FILE *f, sequence_t *seq) {

  if (seq == NULL || seq->snam == NULL || *seq->snam == '\0') return 0;

  (void)fprintf(f, "@%s\n%s\n", seq->snam, seq->sseq);
  (void)fprintf(f, "+%s\n%s\n", seq->snam, seq->squa);

  return 0; }

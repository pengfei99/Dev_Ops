
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <err.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "fastq.h"

typedef struct {
  unsigned char qua;
  char *pfx;
  int len, mask, trim, decr;
  float bad;
} options_t;

static int decr(sequence_t *, options_t *);
static int mask(sequence_t *, options_t *);
static int mini(sequence_t *, options_t *);
static int over(sequence_t *, options_t *);
static int trim(sequence_t *, options_t *);
static int filter(sequence_t *, options_t *);
static void usage(char *);

int main(int argc, char **argv) {
  FILE *in1, *in2, *ou1, *ou2, *ous, *fd1, *fd2;
  char *prg, *ifile1, *ifile2, *ofile1, *ofile2, *ofiles;
  int i;
  size_t len;
  options_t opt;
  sequence_t seq1, seq2;

  /* Inits */
  prg = basename(*argv);
  opt.pfx = prg;
  opt.bad = 100.0;
  opt.qua = '@';
  opt.len = opt.mask = 0;
  opt.trim = opt.decr = 0;

  /* Command line */
  while ((i = getopt(argc, argv, "b:dhl:mp:q:t")) != -1) {
    switch (i) {
    case 'b':
      opt.bad = atoi(optarg); break;
    case 'd':
      opt.decr = 1; break;
    case 'h':
      usage(prg); return EXIT_SUCCESS;
    case 'l':
      opt.len = atoi(optarg); break;
    case 'm':
      opt.mask = 1; break;
    case 'p':
      opt.pfx = optarg; break;
    case 'q':
      opt.qua += atoi(optarg); break;
    case 't':
      opt.trim = 1; break;
    default:
      usage(prg); return EXIT_FAILURE; }
  }
  if (argc - optind < 1 || argc - optind > 2) {
    usage(prg); return EXIT_FAILURE; }

  /* FIXME: Process sequence files */
  ifile1 = *(argv+optind);
  ifile2 = (argc - optind == 2) ? *(argv+optind+1) : NULL;
  if (ifile1 != NULL && (in1 = fopen(ifile1, "r")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ifile1);
  if (ifile2 != NULL && (in2 = fopen(ifile2, "r")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ifile2);
  len = strlen(opt.pfx) + 2 + 1 + 2;
  ofile1 = malloc(len+1); (void)sprintf(ofile1, "%s_1.fq", opt.pfx);
  ofile2 = malloc(len+1); (void)sprintf(ofile2, "%s_2.fq", opt.pfx);
  ofiles = malloc(len+1); (void)sprintf(ofiles, "%s_s.fq", opt.pfx);
  if (ifile1 != NULL && (ou1 = fopen(ofile1, "w")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ofile1);
  if (ifile2 != NULL && (ou2 = fopen(ofile2, "w")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ofile2);
  if (ifile2 != NULL && (ous = fopen(ofiles, "w")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ofiles);

  fastq_init(&seq1);
  fastq_init(&seq2);

  while (/*CONSTCOND*/ 1) {

    if (ifile1 != NULL) { fastq_read(in1, &seq1); }
    if (ifile2 != NULL) { fastq_read(in2, &seq2); }
    if (feof(in1) != 0) break;
    if (ifile1 != NULL) { filter(&seq1, &opt); }
    if (ifile2 != NULL) { filter(&seq2, &opt); }
    fd1 = ou1; fd2 = ou2;
    if (ifile2 != NULL && (*seq1.snam == '\0' || *seq2.snam == '\0')) {
      fd1 = fd2 = ous; }
    if (ifile1 != NULL) { fastq_write(fd1, &seq1); }
    if (ifile2 != NULL) { fastq_write(fd2, &seq2); }

  }

  fastq_fini(&seq2);
  fastq_fini(&seq1);

  if (ifile2 != NULL && fclose(ous) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ofiles);
  if (ifile2 != NULL && fclose(ou2) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ofile2);
  if (ifile1 != NULL && fclose(ou1) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ofile1);
  free(ofiles);
  free(ofile2);
  free(ofile1);
  if (ifile2 != NULL && fclose(in2) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ifile2);
  if (ifile1 != NULL && fclose(in1) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ifile1);

  return EXIT_SUCCESS; }


static int filter(sequence_t *seq, options_t *opt) {

  if (seq == NULL || seq->snam == NULL) { return 0; }

  /* Check overall quality */
  if (over(seq, opt) != 0) { return 0; }
  /* Mask low quality bases */
  if (opt->mask != 0 && mask(seq, opt) != 0) { return 0; }
  /* Decrease low quality values */
  if (opt->decr != 0 && decr(seq, opt) != 0) { return 0; }
  /* Trim low quality bases on both ends */
  if (opt->trim != 0 && trim(seq, opt) != 0) { return 0; }
  /* Check minimum length */
  if (mini(seq, opt) != 0) { return 0; }

  return 0; }


/* Decrease low quality values */
static int decr(sequence_t *seq, options_t *opt) {
  char *q;

  if (*seq->snam == '\0') { return 0; }

  q = seq->squa;
  while (*q) {
    if (*q < opt->qua) { *q = '@' + 2; }
    q++; }

  return 0; }


/* Mask low quality */
static int mask(sequence_t *seq, options_t *opt) {
  char *q;

  if (*seq->snam == '\0') { return 0; }

  q = seq->squa;
  while (*q) {
    if (*q < opt->qua) { *(seq->sseq+(q-seq->squa)) = 'N'; }
    q++; }

  return 0; }


/* Check minimum length */
static int mini(sequence_t *seq, options_t *opt) {

  if (*seq->snam == '\0') { return 0; }

  /* Check minimum length */
  if (strlen(seq->sseq) < opt->len) { *seq->snam = '\0'; }

  return 0; }


/* Check overall quality */
static int over(sequence_t *seq, options_t *opt) {
  char *q;
  float min;
  size_t bad = 0;

  if (*seq->snam == '\0') { return 0; }

  q = seq->squa;
  while (*q) {
    if (*q < opt->qua) { bad++; }
    q++; }

  min = strlen(seq->squa) * opt->bad / 100.0;
  if ((float)bad >= min) { *seq->snam = '\0'; }

  return 0; }


/* Trim both ends */
static int trim(sequence_t *seq, options_t *opt) {
  char *q;
  size_t len;

  if (*seq->snam == '\0') { return 0; }

  q = seq->squa;
  while (*q) { if (*q >= opt->qua) break; q++; }
  len = strlen(q);
  memmove(seq->sseq, seq->sseq+(q-seq->squa), len + 1);
  memmove(seq->squa, q, len + 1);
  q = seq->squa + len;
  while (q > seq->squa) {
    if  (*q >= opt->qua) break;
    *(seq->sseq + (q - seq->squa)) = '\0';
    *q = '\0';
    q--; }

  return 0; }


static void usage(char *prg) {
  FILE *f = stderr;

  (void)fprintf(f, "usage: %s [options] <file> [<file>]\n", basename(prg));
  (void)fprintf(f, "\noptions:\n");
  (void)fprintf(f, "  -b <val> ... Overall bad quality maximum percent.\n");
  (void)fprintf(f, "  -d       ... Decrease low quality value to minmum.\n");
  (void)fprintf(f, "  -h       ... Print this message and exit.\n");
  (void)fprintf(f, "  -l <val> ... Minimum sequence length.\n");
  (void)fprintf(f, "  -m       ... Mask low quality bases.\n");
  (void)fprintf(f, "  -p <str> ... Name prefix for output files.\n");
  (void)fprintf(f, "  -q <val> ... Quality value cutoff.\n");
  (void)fprintf(f, "  -t       ... Trim low quality bases on both ends.\n");

  return; }


#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <err.h>
#include <libgen.h>
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#ifdef USE_BSDMD5
# ifdef HAVE_MD5_H
#  include <md5.h>
# endif
# ifdef HAVE_BSD_MD5_H
#  include <bsd/md5.h>
# endif
#endif

#ifdef USE_SSLMD5
# ifdef HAVE_OPENSSL_MD5_H
#  include <openssl/md5.h>
# endif
# define MD5Init MD5_Init
# define MD5Update MD5_Update
# define MD5Final MD5_Final
#endif

#include "fastq.h"

#ifdef _LP64
#define U64_PRINT "lu"
#else
#define U64_PRINT "llu"
#endif

static void usage(char *);


int main(int argc, char **argv) {
  FILE *in1, *in2;
  char *prg, *ifile1, *ifile2;
  int i;
  sequence_t seq1, seq2;
  MD5_CTX md5;

  unsigned char xx[16];
  uint64_t val;

  /* Inits */
  prg = basename(*argv);

  /* Command line */
  while ((i = getopt(argc, argv, "h")) != -1) {
    switch (i) {
    case 'h':
      usage(prg); return EXIT_SUCCESS;
    default: break; }
  }
  if (argc - optind < 1 || argc - optind > 2) {
    usage(prg); return EXIT_FAILURE; }

  /* Process sequence files */
  ifile1 = *(argv+optind);
  ifile2 = (argc - optind == 2) ? *(argv+optind+1) : NULL;
  if (ifile1 != NULL && (in1 = fopen(ifile1, "r")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ifile1);
  if (ifile2 != NULL && (in2 = fopen(ifile2, "r")) == NULL)
    err(EXIT_FAILURE, "%s: open failed", ifile2);

  fastq_init(&seq1);
  fastq_init(&seq2);

  while (/*CONSTCOND*/ 1) {

    if (ifile1 != NULL) { fastq_read(in1, &seq1); }
    if (ifile2 != NULL) { fastq_read(in2, &seq2); }
    if (feof(in1) != 0) break;

    MD5Init(&md5);
    if (ifile1 != NULL) { MD5Update(&md5, seq1.sseq, seq1.lseq); }
    if (ifile2 != NULL) { MD5Update(&md5, seq2.sseq, seq2.lseq); }
    MD5Final(xx, &md5);

    val = 0;
    for (i = 0; i < seq1.lqua; i++) {
      val += *(seq1.squa+i) - 64;
      if (ifile2 == NULL) continue;
      val += *(seq2.squa+i) - 64; }

    for (i = 0; i < 16; i++) { printf("%02x", xx[i]); }
    printf("\t%" U64_PRINT "\t%s\n", val, seq1.snam);

  }

  fastq_fini(&seq2);
  fastq_fini(&seq1);

  if (ifile2 != NULL && fclose(in2) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ifile2);
  if (ifile1 != NULL && fclose(in1) == EOF)
    err(EXIT_FAILURE, "%s: close failed", ifile1);

  return EXIT_SUCCESS; }


static void usage(char *prg) {
  FILE *f = stderr;

  (void)fprintf(f, "usage: %s [options] <file> [<file>]\n", basename(prg));
  (void)fprintf(f, "\noptions:\n");
  (void)fprintf(f, "  -h       ... Print this message and exit.\n");

  return; }

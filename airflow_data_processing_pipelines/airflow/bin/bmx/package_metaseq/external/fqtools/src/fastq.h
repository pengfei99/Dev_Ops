/* fastq.h - FASTQ sequence file functions */

#include <stddef.h>
#include <stdio.h>

typedef struct {
  size_t lnam; char *snam;
  size_t lseq; char *sseq;
  size_t lqua; char *squa;
} sequence_t;

int fastq_init(sequence_t *);
int fastq_fini(sequence_t *);
int fastq_read(FILE *, sequence_t *);
int fastq_write(FILE *, sequence_t *);


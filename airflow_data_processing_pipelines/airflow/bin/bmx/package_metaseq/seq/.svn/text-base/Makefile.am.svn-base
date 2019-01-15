LDADD = $(LIBGDL_LIBS) $(MATH_LIB) -L/Softs/bioinfo/lib/ -lpthread -lz -lbam # -lsparsehash
#LDADD = $(LIBGDL_LIBS) $(MATH_LIB) -lpthread -lz -lbam # -lsparsehash
INCLUDES= $(LIBGDL_CFLAGS) -I./ -I../ -I../utils


bin_PROGRAMS = mgx-seq-bfdb       \
	mgx-seq-bfclass    \
	mgx-seq-bwabh      \
	mgx-seq-bam2readqc \
	mgx-seq-bam2var    \
	mgx-seq-bam2bh     \
	mgx-seq-drawfrag   \
	mgx-seq-faget      \
	mgx-seq-fadesc     \
	mgx-seq-famut      \
	mgx-seq-favar      \
	mgx-seq-fqdesc     \
	mgx-seq-fqget      \
	mgx-seq-fq2fa      \
	mgx-seq-fa2fq      \
	mgx-seq-fqtrim     \
	mgx-seq-fqboot     \
	mgx-seq-fasplit    \
	mgx-seq-famergpair \
	mgx-seq-fa2libsvm  \
	mgx-seq-fa2vw	\
	mgx-seq-kmertab    \
	mgx-seq-kmerdb     \
	mgx-seq-kmernbfit  \
	mgx-seq-kmernbpred \
	mgx-seq-kmerdbdesc \
	mgx-seq-uniprotid \
	mgx-seq-bams2pos \
	mgx-seq-baminfo \
	mgx-seq-epsNB2taxons \
 	mgx-seq-fqmv \
        mgx-seq-fqsim

# Bloom-filter
mgx_seq_bfdb_SOURCES          = mgx-seq-bfdb.c ../utils/gzutil.c ../utils/hash.c bloom.c fasta.c
mgx_seq_bfclass_SOURCES       = mgx-seq-bfclass.c ../utils/gzutil.c ../utils/hash.c bloom.c fasta.c
# Bam
mgx_seq_bwabh_SOURCES         = mgx-seq-bwabh.c
mgx_seq_bam2readqc_SOURCES    = mgx-seq-bam2refqc.c
mgx_seq_bam2var_SOURCES       = mgx-seq-bam2var.c
mgx_seq_bam2bh_SOURCES        = mgx-seq-bams2bh.c
mgx_seq_bams2pos_SOURCES      = mgx-seq-bams2pos.c
mgx_seq_baminfo_SOURCES       = mgx-seq-baminfo.c  
#mgx_seq_bam2Stats_SOURCES     = mgx-seq-bam2Stats.c
# Fasta / Fastq
mgx_seq_faget_SOURCES     = mgx-seq-faget.c ../utils/gzutil.c
mgx_seq_fadesc_SOURCES    = mgx-seq-fadesc.c ../utils/gzutil.c
mgx_seq_famut_SOURCES     = mgx-seq-famut.c ../utils/gzutil.c
mgx_seq_favar_SOURCES     = mgx-seq-favar.c ../utils/gzutil.c
mgx_seq_fqdesc_SOURCES    = mgx-seq-fqdesc.c ../utils/gzutil.c
mgx_seq_fqget_SOURCES     = mgx-seq-fqget.c ../utils/gzutil.c
mgx_seq_fq2fa_SOURCES     = mgx-seq-fq2fa.c ../utils/gzutil.c
mgx_seq_fa2fq_SOURCES     = mgx-seq-fa2fq.c ../utils/gzutil.c
mgx_seq_fqtrim_SOURCES    = mgx-seq-fqtrim.c ../utils/gzutil.c
mgx_seq_fqboot_SOURCES    = mgx-seq-fqboot.c ../utils/gzutil.c
mgx_seq_fasplit_SOURCES    = mgx-seq-fasplit.c ../utils/gzutil.c
mgx_seq_famergpair_SOURCES = mgx-seq-famergpair.c ../utils/gzutil.c
mgx_seq_fa2libsvm_SOURCES  = mgx-seq-fa2libsvm.c ../utils/gzutil.c
mgx_seq_fa2vw_SOURCES = mgx-seq-fa2vw.c ../utils/gzutil.c
mgx_seq_fqsim_SOURCES = mgx-seq-fqsim.c ../utils/gzutil.c
mgx_seq_fqmv_SOURCES = mgx-seq-fqmv.c ../utils/gzutil.c
# Kmer
mgx_seq_kmertab_SOURCES       = mgx-seq-kmertab.c ../utils/gzutil.c
mgx_seq_kmerdb_SOURCES        = mgx-seq-kmerdb.c kmer.c
mgx_seq_kmernbfit_SOURCES        = mgx-seq-kmernbfit.c kmer.c ../taxo/taxo.c ../taxo/ncbi_taxo.c ../taxo/simple_taxo.c
mgx_seq_kmernbpred_SOURCES        = mgx-seq-kmernbpred.c kmer.c ../taxo/taxo.c ../taxo/ncbi_taxo.c ../taxo/simple_taxo.c
mgx_seq_kmerdbdesc_SOURCES        = mgx-seq-kmerdbdesc.c kmer.c ../taxo/taxo.c ../taxo/ncbi_taxo.c ../taxo/simple_taxo.c
mgx_seq_epsNB2taxons_SOURCES	= mgx-seq-epsNB2taxons.c
# db
mgx_seq_uniprotid_SOURCES   = mgx-seq-uniprotid.c ../utils/gzutil.c
# drawfrag
mgx_seq_drawfrag_SOURCES = mgx-seq-drawfrag.c ../utils/gzutil.c
EXTRA_DIST = hash.h bloom.h

m4datadir = $(datadir)/aclocal

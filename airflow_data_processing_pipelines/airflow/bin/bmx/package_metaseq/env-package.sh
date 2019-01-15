PACKAGE=/mnt/gpfs/pt6/airflow/bin/bmx/package_metaseq

# Mixgenomix 
MGX_SEQ=${PACKAGE}/seq 
MGX_TAXO=${PACKAGE}/taxo 
MGX_SHELL=${PACKAGE}/scripts/shell
MGX_PERL=${PACKAGE}/scripts/perl
MGX_R=${PACKAGE}/scripts/R
MGX_EXT=${PACKAGE}/ext
MGX_SHELL_LIB=${PACKAGE}/library/shell
MGX_PERL_LIB=${PACKAGE}/library/perl

PATH=${MGX_R}:${MGX_SEQ}:${MGX_TAXO}:${MGX_SHELL}:${MGX_PERL}:${MGX_SHELL_LIB}:$PATH

# # Softs
EXT=${PACKAGE}/external/
export A5MISEQ=${EXT}/A5MiSeq
PATH=${A5MISEQ}:$PATH
PATH=${EXT}/FastQC:$PATH
PATH=${EXT}/sickle:$PATH
PATH=${EXT}/trimmomatic:$PATH
PATH=${EXT}/fqtools/bin:$PATH
PATH=${EXT}/FLASH-1.2.11:$PATH
PATH=${EXT}/bam:$PATH
PATH=${EXT}/kseq:$PATH
PATH=${EXT}/sparsehash:$PATH
PATH=${EXT}/samtools/bin:$PATH

LD_LIBRARY_PATH=${EXT}/lib:${LD_LIBRARY_PATH}
# 
export PATH
export LD_LIBRARY_PATH 

#!/bin/bash

echo -e "\nBEGIN MGX-SEQ16S-METAGENOMICS\n"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================
METAG_TIME_TOT=${SECONDS}

#=======================================================================================================
#
# LOAD BASH FUNCTIONS
#
#=======================================================================================================

source bash_functions.lib

#=======================================================================================================
#
# USAGE
#
#=======================================================================================================

usage(){
cat <<EOF
usage: $0 options

	This script performs a metagenomics targeted/shotgun analysis based on comparative approaches.
	The program performs the following steps :
		- Reads filtering/trimming and QC
		- Host filtering (human filtering)
		- Parallel reads mapping against reference DB
		- BAM files merging
		- LCA retrieval

DOC:
	A BioTechno documentation of this script is available: http://biopedia.biomerieux.net/wiki/biotechno/index.php/mgx-seq16S-metagenomics.sh (TODO)

INPUTS:
	-c		Path to configuration file (mandatory)
	-i		Path to input reads file (fastq format) (mandatory)
	-I		Path to input reads file (fastq format) (optional, mandatory for paired-end data)
	-o		Path to the output directory (mandatory)

OUTPUTS:
	In the output directory (-o option) you can find :
		- bamsToMerge.txt                : path to BAM files to merge
		- *_allBestHit.txt.gz            : gziped file containing gi of all best hits for all the reads
		- *_allBestHit_metag.txt         : text file containing number of mapped reads for each taxon
		- *_allBestHitTaxid.txt.gz       : gziped file containing taxid of all the best hits for all the reads
		- *_allReads.txt                 : text file containing all reads ID
		- *_LCA.txt.gz                   : gziped file containing LCA from each read based on their unique or multiple hits
		- 1 or 3 *_fastq.zip             : archive from FASTQC analyse, 1 for single-end data, 3 for paired-end data (forward, reverse and singleton)
		- 1 or 3 *_fastqc directory(ies) : from FASTQC analyse, 1 for single-end data, 3 for paired-end data (forward, reverse and singleton)
		- HostFiltering directory
		- inputMap.txt                   : gi2taxids for all the reference taxons
		- summary.txt                    : summury of counting reads after each step
		- time.txt                       : listing of each time step
		- Several log files

	There are also as many mapping directories as TOT_STEP_MAPPING_METAG steps defined in the config file.
	The names of the subdirectories are defined in the OUTPUT_MAPPING_TABLE table in the config file.
	Each output subdirectoy(ies) contains:
		- Basename.filtered.step1.sorted.bam: sorted BAM file corresponding to the mapping step
		- Basename.filtered.step1_log.out: Log file for the mapping

DEPENDENCIES:
	- mgx-seq-mapping.sh
	- fqPreproc.sh
	- mgx-seq-host-filter.sh
	- mgx-seq-bam2bh
	- mgx-seq-baminfo
	- mgx-taxo-gi2tax
	- mgx-taxo-lca
EOF
}

#=======================================================================================================
#
# BY DEFAULT VALUES
#
#=======================================================================================================

BAM2BH_OPTIONS=""

#=======================================================================================================
#
# GET THE PROGRAMM ARGUMENTS
#
#=======================================================================================================

while getopts "c:i:I:o:" PARAMETER
do
	case ${PARAMETER} in

		# CONFIG FILE
		c) CONF=${OPTARG};;

		# PATH TO THE INPUT READS FILE
		i) INPUT_READS=${OPTARG};;

		# PATH TO THE SECOND INPUT READS FILE
		I) INPUT_READS_PAIR2=${OPTARG};;

		# PATH TO THE OUTPUT DIRECTORY
		o) OUTPUT=${OPTARG};;

		:) echo " Option -${OPTARG} expects an argument " ; exit ;;
		\?) echo " Unvalid option ${OPTARG} " ; exit ;;

	esac
done

if [[ -z ${CONF} || -z ${INPUT_READS} || -z ${OUTPUT} ]]; then

	usage
	exit 1

fi


SOURCE_DIRECTORY="/Projets/PRG0023-Technology_Research_Program/B2723-Identification_and_Detection/Studies/WP2-Samba-Metagenomic/WP2.2-Stools/80-Airflow_test/src"
#=======================================================================================================
#
# PERFORM READS FILTERING AND QC
#
#=======================================================================================================

${SOURCE_DIRECTORY}/bmx_preproc.sh -c ${CONF} -i ${INPUT_READS} -I ${INPUT_READS_PAIR2} -o ${OUTPUT}

# #=======================================================================================================
# #
# # MERGED PAIRED-END READS
# #
# #=======================================================================================================

${SOURCE_DIRECTORY}/bmx_merge.sh -c ${CONF} -i ${INPUT_READS} -I ${INPUT_READS_PAIR2} -o ${OUTPUT}

# #=======================================================================================================
# #
# # MAP READS IN PARALLEL ONTO THE REFERENCE DATABASES
# #
# #=======================================================================================================

${SOURCE_DIRECTORY}/bmx_mapping.sh -c ${CONF} -i ${INPUT_READS} -o ${OUTPUT}

# #=======================================================================================================
# #
# # MERGE BAM FILES IF NECESSARY
# #
# #=======================================================================================================

${SOURCE_DIRECTORY}/bmx_merge_bam.sh -c ${CONF} -i ${INPUT_READS} -o ${OUTPUT}

# #=======================================================================================================
# #
# # LCA
# #
# #=======================================================================================================
${SOURCE_DIRECTORY}/bmx_lca.sh -c ${CONF} -i ${INPUT_READS} -I ${INPUT_READS_PAIR2} -o ${OUTPUT}


${SOURCE_DIRECTORY}/mgx-metagenomic-analyses.sh -i ${OUTPUT}/Analyse/bmx_analyses_label.txt -o ${OUTPUT}/Analyse -t /Master_Data/BioTaxon/NCBI_Taxonomy/20170223
# # #=======================================================================================================
# # #
# # # STOPING TIMER
# # #
# # #=======================================================================================================

echo -e "\nTotal running time for mgx-seq16S-metagenomics.sh : $( gettime ${METAG_TIME_TOT} ) (minutes:secondes)" >> ${OUTPUT}/total_time.txt

echo -e "\nEND MGX-SEQ16S-METAGENOMICS\n"
sed -i "s|\(PAIRED=\)\(.*\)|\11|" ${CONF}

exit 0

#!/bin/bash

echo -e "\nBEGIN MGX-SEQ16S-METAGENOMICS\n"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================

METAG_TIME=${SECONDS}

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
	- mapping.sh
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

#=======================================================================================================
#
# LOAD CONFIGURATION FILE
#
#=======================================================================================================

source ${CONF}

#=======================================================================================================
#
# USAGE RESTRICTIONS TESTS
#
#=======================================================================================================

if [[ ${DO_FILTERING_QC} -ne 0 && ${DO_FILTERING_QC} -ne 1 ]] ;     then echo -e "\nVariable DO_FILTERING_QC must be equal to 0 or 1 in your config file\n"              ; exit 1 ; fi
if [[ ${DO_HOST_FILTERING} -ne 0 && ${DO_HOST_FILTERING} -ne 1 ]] ; then echo -e "\nVariable DO_HOST_FILTERING must be equal to 0 or 1 in your config file\n"            ; exit 1 ; fi
if [[ ${DO_MAPPING} -ne 0 && ${DO_MAPPING} -ne 1 ]] ;               then echo -e "\nVariable DO_MAPPING must be equal to 0 or 1 in your config file\n"                   ; exit 1 ; fi
if [[ ${DO_BAM_MERGE} -ne 0 && ${DO_BAM_MERGE} -ne 1 ]] ;           then echo -e "\nVariable DO_BAM_MERGE must be equal to 0 or 1 in your config file\n"                 ; exit 1 ; fi
if [[ ${DO_LCA} -ne 0 && ${DO_LCA} -ne 1 ]] ;                       then echo -e "\nVariable DO_LCA must be equal to 0 or 1 in your config file\n"                       ; exit 1 ; fi
if [[ ${DO_LCA} -eq 1 && ${DO_BAM_MERGE} -eq 0 ]] ;                 then echo -e "\nVariable DO_BAM_MERGE must be equal to 1 if you want retrieve LCA from your reads\n" ; exit 1 ; fi

if [[ ${GZ_BOOL_METAG} -eq 1 && ${GZ_BOOL_METAG} -ne 1 ]] ; then echo -e "\nVariable GZ_BOOL_METAG must be equal to 0 or 1 in your config file\n" ; exit 1 ; fi
if [[ ${PAIRED} -ne 0 && ${PAIRED} -ne 1 ]] ;               then echo -e "\nVariable PAIRED must be equal to 0 or 1 in your config file\n"        ; exit 1 ; fi

if [[ ${SGE_METAG} -ne 0 && ${SGE_METAG} -ne 1 ]] ;         then echo -e "\nVariable SGE_METAG must be equal to 0 or 1 in your config file\n"     ; exit 1 ; fi
if [[ ${VERBOSE_METAG} -ne 0 && ${VERBOSE_METAG} -ne 1 ]] ; then echo -e "\nVariable VERBOSE_METAG must be equal to 0 or 1 in your config file\n" ; exit 1 ; fi
if [[ ${WRITE_TMP} -ne 0 && ${WRITE_TMP} -ne 1 ]] ;         then echo -e "\nVariable WRITE_TMP must be equal to 0 or 1 in your config file\n"     ; exit 1 ; fi

if [[ ${DO_FILTERING_QC} -eq 1 ]] ; then
	if [[ ${MIN_READ_LENGTH} -lt 1 ]] ;                                           then echo -e "\nVariable MIN_READ_LENGTH must be equal or higher than 1\n"                                                        ; exit 1 ; fi
	if [[ ${QUAL_THRESHOLD} -lt 0 || ${QUAL_THRESHOLD} -gt 40 ]] ;                then echo -e "\nVariable QUAL_THRESHOLD must be between 0 and 40\n"                                                               ; exit 1 ; fi
	if [[ ${PERCENT_CONFIDENT_BPS} -lt 0 || ${PERCENT_CONFIDENT_BPS} -gt 100 ]] ; then echo -e "\nVariable PERCENT_CONFIDENT_BPS must be between 0 and 100\n"                                                       ; exit 1 ; fi
	if [[ ${MISEQ_PREPROC} -ne 0 && ${MISEQ_PREPROC} -ne 1 ]] ;                   then echo -e "\nVariable MISEQ_PREPROC must be equal to 0 or 1 for paired-end data from MiSeq"                                    ; exit 1 ; fi
	if [[ ${MISEQ_PREPROC} -eq 1 && ${PAIRED} -ne 1 ]] ;                          then echo -e "\nVariable PAIRED must be 1 to perform MiSeq preprocessing. With single-end data, use 0 for MISEQ_PREPROC variable" ; exit 1 ; fi
fi

if [[ ${DO_HOST_FILTERING} -eq 1 ]]
then
	if [[ ${METHOD} != "compo" && ${METHOD} != "compa" ]] ; then echo -e "\nVariable METHOD must be equal to \"compo\" or \"compa\" in your config file\n" ; exit 1 ; fi
fi

if [[ ${TOT_STEP_MAPPING_METAG} -lt 1 ]] ;   then echo -e "Variable TOT_STEP_MAPPING_METAG must be equal or greater than 1" ; exit 1 ; fi
if [[ ${SEQUENTIAL_MAPPING_METAG} -ne 0 ]] ; then echo -e "\nVariable SEQUENTIAL_MAPPING_METAG must be equal to 0.\n"       ; exit 1 ; fi

if [[ ${SGE} -ne 0 ]] ; then echo -e "\nVariable SGE must be equal to 0 in your config file.\n" ; exit 1 ; fi

if [[ ${GZ_BOOL} -ne 0 ]] ; then echo -e "\nVariable GZ_BOOL must be equal to 0 in your config file because FASTQ will never be gzipped in mgx-seq-mapping.sh. If they are gzipped, this scripts gunzipd them at the beginning !\n" ; exit 1 ; fi

if [[ ${VERBOSE} -ne 0 && ${VERBOSE} -ne 1 ]] ;   then echo -e "\nVariable VERBOSE must be equal to 0 or 1 in your config file\n"  ; exit 1 ; fi
if [[ ${CLEANING} -ne 0 && ${CLEANING} -ne 1 ]] ; then echo -e "\nVariable CLEANING must be equal to 0 or 1 in your config file\n" ; exit 1 ; fi

if [[ ${TOT_STEP} -ne 1 ]] ;                        then echo -e "\nTOT_STEP must be equal to 1 in your config file for the moment. Doesn't work for greater than 1\n" ; exit 1 ; fi
if [[ ${SEQUENTIAL} -ne 0 ]] ;                      then echo -e "\nSEQUENTIAL must be equal to 0 in your config file for the moment.\n"                               ; exit 1 ; fi
if [[ ${COMPRESS_ALIGNMENT} -ne 1 ]] ;              then echo -e "\nVariable COMPRESS_ALIGNMENT must be equal to 1 in your config file\n"                              ; exit 1 ; fi
if [[ ${SAM_SORT_LEXICO} -ne 1 ]] ;                 then echo -e "\nVariable SAM_SORT_LEXICO must be equal to 1 in your config file\n"                                 ; exit 1 ; fi
if [[ ${FASTQ_OUT} -ne 0 && ${FASTQ_OUT} -ne 1 ]] ; then echo -e "\nVariable FASTQ_OUT must be equal to 0 or 1 in your config file\n"                                  ; exit 1 ; fi

if [[ ${PAIRED} -eq 1 && -z ${INPUT_READS_PAIR2} ]] ; then echo "You should provide the path to the file of the second pairs of reads" ; exit 1 ; fi

# SINGLE-END DATA
if [[ ${PAIRED} -eq 0 ]] ; then

	SE_MAPPERS="bwa-sw bwa-mem bowtie2 tmap bwa"
	SE_MAPPER_OK=0

	for MAP in ${SE_MAPPERS}
	do
		if [[ ${nameOFmappers} == ${MAP} ]] ; then SE_MAPPER_OK=1 ; fi #SE_MAPPER_OK PASSE A 1 SI ON A UN BON MAPPER
	done

	if [[ ${SE_MAPPER_OK} -eq 0 ]] ; then echo "${nameOFmappers} : bad mapper for SINGLE-END reads" ; exit 0 ; 	fi

fi

# PAIRED-END DATA
if [[ ${PAIRED} -eq 1 ]] ; then

	if [[ ${DO_MERGE_READS} -eq 0 ]] ; then

		PE_MAPPERS="bwa-sw bwa-mem-paired bowtie2-paired bwa-paired tmap-paired"
		PE_MAPPER_OK=0

		for MAP in $PE_MAPPERS
		do
			if [[ $nameOFmappers == ${MAP} ]] ; then PE_MAPPER_OK=1 ; fi #PE_MAPPER_OK PASSE A 1 SI ON A UN BON MAPPER
		done

		if [[ ${PE_MAPPER_OK} -eq 0 ]] ; then echo "${nameOFmappers} : bad mapper for PAIRED-END reads" ; exit 0 ; fi

	else

		SE_MAPPERS="bwa-sw bwa-mem bowtie2 tmap bwa"
		SE_MAPPER_OK=0

		for MAP in ${SE_MAPPERS}
		do
			if [[ ${nameOFmappers} == ${MAP} ]] ; then SE_MAPPER_OK=1 ; fi #SE_MAPPER_OK PASSE A 1 SI ON A UN BON MAPPER
		done

		if [[ ${SE_MAPPER_OK} -eq 0 ]] ; then echo "${nameOFmappers} : bad mapper for MERGED (single-end) reads" ; exit 0 ; fi

	fi

fi

# OUTPUT EXISTS
if [[ ! -d ${OUTPUT} ]] ; then
	mkdir -p ${OUTPUT}
fi

if [[ ${SGE_METAG} -eq 1 ]] ; then
	SGE_PREFIX_WAIT_THREADS="qsub -sync y -V -b y -pe smp ${THREADS} -P ${PROJECT} -j y"
	SGE_PREFIX_WAIT="qsub -sync y -b y -V -j y -P ${PROJECT}"
	SGE_PREFIX_THREADS="qsub -V -b y -pe smp ${THREADS} -j y -P ${PROJECT}"
fi

# DETERMINE GZIP STATUS FROM READ FILE EXTENSION AND UNGZIP IF NECESSARY
if [[ ${GZ_BOOL_METAG} -eq 1 ]] ; then

	if [[ ${SGE_METAG} -eq 0 ]] ; then
		gunzip ${INPUT_READS}
	fi

	if [[ ${SGE_METAG} -eq 1 ]] ; then
		eval "${SGE_PREFIX_WAIT} -o /dev/null gunzip ${INPUT_READS}"
	fi

	INPUT_READS=${INPUT_READS%.gz}

	if [[ ${PAIRED} -eq 1 ]] ; then

		if [[ ${SGE_METAG} -eq 0 ]] ; then
			gunzip ${INPUT_READS_PAIR2}
		fi

		if [[ ${SGE_METAG} -eq 1 ]] ; then
			eval "${SGE_PREFIX_WAIT} -o /dev/null gunzip ${INPUT_READS_PAIR2}"
		fi

		INPUT_READS_PAIR2=${INPUT_READS_PAIR2%.gz}

	fi
fi

# GET INITIAL FASTQ PATH TO GZIP AT THE END
INITIAL_FASTQ_1=${INPUT_READS}
if [[ ${PAIRED} -eq 1 ]] ; then INITIAL_FASTQ_2=${INPUT_READS_PAIR2} ; fi

# DEFINE THE TMP DIRECTORY TO WRITE PIPELINE OUTPUTS IN THE TMP DIRECTORY
TS=$( date +%T )
if [[ ${WRITE_TMP} -eq 1 && ${SGE_METAG} -eq 1 ]] ; then
	OUTPUT_SECUREMETAG_TMP=secureShotgunMetag_${TS}
	OUTPUT_TMP=/data/TMP/${OUTPUT_SECUREMETAG_TMP}
else
	OUTPUT_TMP=${OUTPUT}
fi

# TRIM READ FILE PATH AND NAME
EXTENSION="fastq"
READS_FILENAME=$( getFilename ${INPUT_READS} )                 ## with the extension
READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} ) ## without the extention
READS_DIRNAME=$( getDirname ${INPUT_READS} )                   ## directory without the final slash

# TRIM READ FILE PATH AND NAME FOR PAIRED DATA IF NECESSARY
if [[ ${PAIRED} -eq 1 ]] ; then
	READS_FILENAME_PAIR2=$( getFilename ${INPUT_READS_PAIR2} )
	READS_BASENAME_PAIR2=$( getBasenameExt ${INPUT_READS_PAIR2} ${EXTENSION} )
fi

##CHECK THAT THERE IS NOT RESIDUAL BAM FILES THAT WE WOULD MERGE BY ERROR
if [[ ${DO_BAM_MERGE} -eq 1 && ${DO_MAPPING} -eq 1 ]]; then

	EACH_STEP_FOR_METAG=1

	while [[ ${EACH_STEP_FOR_METAG} -le ${TOT_STEP_MAPPING_METAG} ]]
	do

		MAPPING_METAG_STEP=$(( ${EACH_STEP_FOR_METAG} - 1 ))
		OUTPUT_MAPPING=${OUTPUT}/${OUTPUT_MAPPING_TABLE[$MAPPING_METAG_STEP]}
		RES_FILE=$( ls ${OUTPUT_MAPPING}/*step*.sorted.bam 2> /dev/null )

		if [[ ${RES_FILE} != "" ]] ; then
			echo -e "\nYou already have mapping file in the output directory corresponding to your read file. You should remove first before launching the pipeline.\nThe files to remove are: ${RES_FILE}\n"
			exit 1
		fi

		EACH_STEP_FOR_METAG=$(( ${EACH_STEP_FOR_METAG} + 1 ))

	done
fi

if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n[ THE BEGINNING ]\n" ; fi

# DEFINE PAIR_SEPARATOR VARIABLE
whichPairsSeparator ${INPUT_READS}

TOTAL_READ_COUNT=0
COUNT_READ_AFTER_QC=0
COUNT_READ_AFTER_HUMAN_FILTERING=0
COUNT_MAPPED_READ=0

if [[ ${VERBOSE_METAG} -eq 1 ]] ; then

	TOTAL_READ_COUNT=$( fqsize ${INPUT_READS} )

	if [[ ${PAIRED} -eq 0 ]] ; then echo -e "\nType of reads : single-end reads"; else echo -e "\nType of reads : paired-end reads"; fi

	echo -e "The reads file to align is  : ${INPUT_READS}"
	echo -e "Total number of reads       : ${TOTAL_READ_COUNT}"
	echo -e "The reads file extension is : ${EXTENSION}"
	echo -e "The reads file dirname      : ${READS_DIRNAME}"
	echo -e "The reads file name is      : ${READS_FILENAME}"
	echo -e "The reads file basename is  : ${READS_BASENAME}\n"

	if [[ ${PAIRED} -eq 1 ]] ; then
		TOTAL_READ_COUNT=$( fqsize ${INPUT_READS_PAIR2} )
		echo -e "The reads file of the second pair to align is  : ${INPUT_READS_PAIR2}"
		echo -e "Total number of reads                          : ${TOTAL_READ_COUNT}"
		echo -e "The reads file name for the second pair is     : ${READS_FILENAME_PAIR2}"
		echo -e "The reads file basename for the second pair is : ${READS_BASENAME_PAIR2}\n"
		echo -e "The mapper for paired-end reads is : ${nameOFmappers}"
	else
		echo -e "The mapper for single-end reads is : ${nameOFmappers}"
	fi

	echo -e "\nThe output directory is : ${OUTPUT}\n"

	if [[ ${DO_FILTERING_QC} -eq 1 ]] ;   then echo -e "Filtering and QC steps : YES"; else echo -e "Filtering and QC steps : NO" ; fi
	if [[ ${DO_HOST_FILTERING} -eq 1 ]] ; then echo -e "Human filtering step   : YES"; else echo -e "Human filtering step   : NO" ; fi
	if [[ ${DO_MERGE_READS} -eq 1 ]] ;    then echo -e "Merging step           : YES"; else echo -e "Merging step           : NO" ; fi
	if [[ ${DO_MAPPING} -eq 1 ]] ;        then echo -e "Mapping step           : YES"; else echo -e "Mapping step           : NO" ; fi
	if [[ ${DO_BAM_MERGE} -eq 1 ]] ;      then echo -e "BAM merging step       : YES"; else echo -e "BAM merging step       : NO" ; fi
	if [[ ${DO_LCA} -eq 1 ]] ;            then echo -e "LCA step               : YES"; else echo -e "LCA step               : NO" ; fi

	if [[ ${GZ_BOOL_METAG} -eq 1 ]] ; then echo -e "\nInput read file(s) are gzipped"; else echo -e "\nInput read file(s) are not gzipped" ; fi
	if [[ ${SGE_METAG} -eq 1 ]] ;     then echo -e "Mode qsub used";                   else echo -e "Mode qsub not used"                   ; fi
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "Mode verbose";                     else echo -e "Mode silence"                         ; fi
	if [[ ${WRITE_TMP} -eq 1 ]] ;     then echo -e "Process in /data/TMP";             else echo -e "Process in output directory\n"        ; fi

	echo -e "The minimum reads length is   : ${MIN_READ_LENGTH}"
	echo -e "The quality treshold is       : ${QUAL_THRESHOLD}"
	echo -e "The minimum percent of bases that must have a quality score higher than the quality threshold is : ${PERCENT_CONFIDENT_BPS}"

	if [[ ${METHOD} == "compa" ]] ; then echo -e "\nHuman filtering by comparative approach\n"; else echo -e "\nHuman filtering by compositionnal approach\n"; fi

	echo -e "The Human RefDB used is                        : ${REF_DB_HUMAN}"
	echo -e "The TaxoDB used is                             : ${TAXO_DB}"
	echo -e "Number of RefDBs used for mapping              : ${TOT_STEP_MAPPING_METAG}"
	echo -e "Number of threads chosen for each mapping step : ${THREADS}"
	echo -e "Project ID to reference jobs                   : ${PROJECT}"
	echo -e "Options for mgx-seq-bam2bh.sh                  : ${BAM2BH_OPTIONS}"
	if [ -z ${BWAMEM_OPTION+x} ];  then echo -e "Options for bwa mem                            : not define"; else echo -e "Options for bwa mem                            : ${BWAMEM_OPTION}";  fi
	if [ -z ${BOWTIE2_OPTION+x} ]; then echo -e "Options for bowtie2                            : not define"; else echo -e "Options for bowtie2                            : ${BOWTIE2_OPTION}"; fi

fi

#=======================================================================================================
#
# PERFORM READS FILTERING AND QC
#
#=======================================================================================================

if [[ ${DO_FILTERING_QC} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#######################################\n###     Filtering and QC: [RUN]     ###\n#######################################\n" ; fi

	# SINGLE-END DATA
	if [[ ${PAIRED} -eq 0 ]] ; then

		READ_COUNT=$( fqsize ${INPUT_READS} )

		echo -e "> Number of reads before QC step : ${READ_COUNT}\n"
		echo "Number of reads before QC step : ${READ_COUNT}" > ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log

		# MISEQ PREPROC NOT AVAILABLE WITH SINGLE END DATA --> THREAD=1
		CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -x ${OUTPUT}/${READS_BASENAME}.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS}"
		echo ${CMD_BASE} >> ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log

		# MODE SGE : NO
		if [[ ${SGE_METAG} -eq 0 ]] ; then

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n"; fi
			eval ${CMD_BASE} > ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log 2>&1

		else # MODE SGE : YES

			CMD_SGE="${SGE_PREFIX_WAIT} -o ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log ${CMD_BASE}"
			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
			eval ${CMD_SGE}

		fi

		INPUT_READS=${OUTPUT}/${READS_BASENAME}.filtered.fastq

		CLEAN_FASTQ_QC=${INPUT_READS}

		READ_COUNT=$( fqsize ${INPUT_READS} )
		echo -e "> Number of reads after QC step : ${READ_COUNT}\n"
		echo "Number of reads after QC step : ${READ_COUNT}" >> ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log
		COUNT_READ_AFTER_QC=${READ_COUNT}

		if [[ ! -s ${INPUT_READS} ]] ; then
			echo "Filtered reads file is empty => abort"
			exit 1
		fi

		READS_FILENAME=$( getFilename ${INPUT_READS} )                 ## with the extension
		READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} ) ## without the extention
		READS_DIRNAME=$( getDirname ${INPUT_READS} )                   ## directory without the final slash

	else # PAIRED-END DATA

		READ_COUNT=$( fqsize ${INPUT_READS} )

		echo -e "> Number of reads before QC step : ${READ_COUNT}\n"
		echo "Number of reads before QC step : ${READ_COUNT}" >> ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log

		# MODE SGE : NO
		if [[ ${SGE_METAG} -eq 0 ]] ; then

			# MISEQ PRPEPROC : YES
			if [[ ${MISEQ_PREPROC} -eq 1 ]] ; then
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/${READS_BASENAME}.filtered.fastq -y ${OUTPUT}/${READS_BASENAME_PAIR2}.filtered.fastq -z ${OUTPUT}/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -n ${THREADS} -s CMC -c ${CLEANING}"
			else # MISEQ PREPROC : NO
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/${READS_BASENAME}.filtered.fastq -y ${OUTPUT}/${READS_BASENAME_PAIR2}.filtered.fastq -z ${OUTPUT}/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS}"
			fi

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n"; fi

			eval ${CMD_BASE} > ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log 2>&1

		else # MODE SGE : YES

			# MISEQ PRPEPROC : YES
			if [[ ${MISEQ_PREPROC} -eq 1 ]] ; then
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/${READS_BASENAME}.filtered.fastq -y ${OUTPUT}/${READS_BASENAME_PAIR2}.filtered.fastq -z ${OUTPUT}/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -n ${THREADS} -s CMC -c ${CLEANING}"
			else # MISEQ PREPROC : NO
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/${READS_BASENAME}.filtered.fastq -y ${OUTPUT}/${READS_BASENAME_PAIR2}.filtered.fastq -z ${OUTPUT}/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS}"
			fi

			# MISEQ PRPEPROC : YES --> THREADS=${THREADS}
			if [[ ${MISEQ_PREPROC} -eq 1 ]] ; then
				SGE_PREFIX_1="qsub -sync y -V -b y -j y -P ${PROJECT} -pe smp ${THREADS}"
			else # MISEQ PRPEPROC : NO --> THREADS=1
				SGE_PREFIX_1="qsub -sync y -V -b y -j y -P ${PROJECT} -pe smp 1"
			fi

			CMD_SGE="${SGE_PREFIX_1} -o ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log ${CMD_BASE}"

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi

			eval ${CMD_SGE}

		fi

		INPUT_READS=${OUTPUT}/${READS_BASENAME}.filtered.fastq
		INPUT_READS_PAIR2=${OUTPUT}/${READS_BASENAME_PAIR2}.filtered.fastq

		CLEAN_FASTQ_QC_PAIR1=${INPUT_READS}
		CLEAN_FASTQ_QC_PAIR2=${INPUT_READS_PAIR2}
		CLEAN_FASTQ_QC_SGL="${OUTPUT}/${READS_BASENAME}.singleton.filtered.fastq"

		READ_COUNT=$( fqsize ${INPUT_READS} )
		echo -e "> Number of reads after QC step : ${READ_COUNT}\n"
		echo "Number of reads after QC step : ${READ_COUNT}\n" >> ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log
		COUNT_READ_AFTER_QC=${READ_COUNT}

		if [[ ! -s ${INPUT_READS} || ! -s ${INPUT_READS_PAIR2} ]] ; then
			echo "Filtered reads files are empty => abort"
			exit 1
		fi

		READS_FILENAME=$( getFilename ${INPUT_READS} )                 ## with the extension
		READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} ) ## without the extention
		READS_DIRNAME=$( getDirname ${INPUT_READS} )                   ## directory without the final slash
		READS_FILENAME_PAIR2=$( getFilename ${INPUT_READS_PAIR2} )
		READS_BASENAME_PAIR2=$( getBasenameExt ${INPUT_READS_PAIR2} ${EXTENSION} )

	fi

	echo -e "> Filtering & QC : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> Filtering & QC : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n########################################\n###     Filtering and QC: [DONE]     ###\n########################################" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#################################################\n###    Filtering and QC steps are omitted     ###\n#################################################" ; fi

fi

#=======================================================================================================
#
# PERFORM HUMAN READS FILTERING
#
#=======================================================================================================

if [[ ${DO_HOST_FILTERING} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n############################################\n###     Human read filtering : [RUN]     ###\n############################################\n" ; fi

	READ_COUNT=$( fqsize ${INPUT_READS} )
	echo -e "> Remaining reads before Host Filtering : ${READ_COUNT}\n"
	echo "> Remaining reads before Host Filtering : ${READ_COUNT}" >> ${OUTPUT}/mgx-seq16S-metagenomics.mgx-seq-host-filter.log

	# SINGLE-END DATA
	if [[ ${PAIRED} -eq 0 ]] ; then

		if [[ ${METHOD} == "compa" ]] ; then
			CMD_BASE="mgx-seq-host-filter.sh -m ${METHOD} -s 0 -i ${INPUT_READS} -r ${REF_DB_HUMAN} -o ${OUTPUT} -p ${PROJECT} -t ${THREADS} -e ${SGE_METAG}"
		elif [[ ${METHOD} == "compo" ]] ; then
			CMD_BASE="mgx-seq-host-filter.sh -m ${METHOD} -s 0 -i ${INPUT_READS} -d ${VW_MODEL} -l ${VW_THRESHOLD} -o ${OUTPUT} -p ${PROJECT} -t ${THREADS} -e ${SGE_METAG}"
		fi

		if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi

		eval ${CMD_BASE} > ${OUTPUT}/mgx-seq16S-metagenomics.mgx-seq-host-filter.log 2>&1

		if [[ ${METHOD} == "compa" ]] ; then
			INPUT_READS=${OUTPUT}/HostFiltering_compa/${READS_BASENAME}.non_host.fastq
		elif [[ ${METHOD} == "compo" ]] ; then
			INPUT_READS=${OUTPUT}/HostFiltering_compo/${READS_BASENAME}.non_host.fastq
		fi

		CLEAN_FASTQ_HOST_FILTER=${INPUT_READS}

		READ_COUNT=$( fqsize ${INPUT_READS} )
		echo -e "> Remaining reads after Host Filtering : ${READ_COUNT}"
		echo "Remaining reads after Host Filtering : ${READ_COUNT}" >> ${OUTPUT}/mgx-seq16S-metagenomics.mgx-seq-host-filter.log
		COUNT_READ_AFTER_HUMAN_FILTERING=${READ_COUNT}

		if [[ ! -s ${INPUT_READS} ]] ; then
			echo "Filtered reads file is empty => abort"
			exit 1
		fi

		READS_FILENAME=$( getFilename ${INPUT_READS} )                 ## with the extension
		READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} ) ## without the extention
		READS_DIRNAME=$( getDirname ${INPUT_READS} )                   ## directory without the final slash

	else # PAIRED-END DATA

		if [[ ${METHOD} == "compa" ]] ; then
			CMD_BASE="mgx-seq-host-filter.sh -m ${METHOD} -s 1 -i ${INPUT_READS} -I ${INPUT_READS_PAIR2} -r ${REF_DB_HUMAN} -o ${OUTPUT} -p ${PROJECT} -t ${THREADS} -e ${SGE_METAG}"
		elif [[ ${METHOD} == "compo" ]] ; then
			CMD_BASE="mgx-seq-host-filter.sh -m ${METHOD} -s 1 -i ${INPUT_READS} -I ${INPUT_READS_PAIR2} -d ${VW_MODEL} -l ${VW_THRESHOLD} -o ${OUTPUT} -p ${PROJECT} -t ${THREADS} -e ${SGE_METAG}"
		fi

		if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi

		eval ${CMD_BASE} > ${OUTPUT}/mgx-seq16S-metagenomics.mgx-seq-host-filter.log 2>&1

		if [[ ${METHOD} == "compa" ]] ; then
			INPUT_READS=${OUTPUT}/HostFiltering_compa/${READS_BASENAME}.pair1.non_host.fastq
			INPUT_READS_PAIR2=${OUTPUT}/HostFiltering_compa/${READS_BASENAME}.pair2.non_host.fastq
		elif [[ ${METHOD} == "compo" ]] ; then
			INPUT_READS=${OUTPUT}/HostFiltering_compo/${READS_BASENAME}.pair1.non_host.fastq
			INPUT_READS_PAIR2=${OUTPUT}/HostFiltering_compo/${READS_BASENAME}.pair2.non_host.fastq
		fi

		CLEAN_FASTQ_HOST_FILTER_PAIR1=${INPUT_READS}
		CLEAN_FASTQ_HOST_FILTER_PAIR2=${INPUT_READS_PAIR2}

		READ_COUNT=$( fqsize ${INPUT_READS} )
		echo -e "> Remaining reads after Host Filtering : ${READ_COUNT}\n"
		echo "> Remaining reads after Host Filtering : ${READ_COUNT}" >> ${OUTPUT}/mgx-seq16S-metagenomics.mgx-seq-host-filter.log
		COUNT_READ_AFTER_HUMAN_FILTERING=${READ_COUNT}

		if [[ ! -s ${INPUT_READS} || ! -s ${INPUT_READS_PAIR2} ]] ; then
			echo "Filtered reads files are empty => abort"
			exit 1
		fi

		READS_FILENAME=$( getFilename ${INPUT_READS} )                 ## with the extension
		READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} ) ## without the extention
		READS_DIRNAME=$( getDirname ${INPUT_READS} )                   ## directory without the final slash
		READS_FILENAME_PAIR2=$( getFilename ${INPUT_READS_PAIR2} )
		READS_BASENAME_PAIR2=$( getBasenameExt ${INPUT_READS_PAIR2} ${EXTENSION} )

	fi

	echo -e "> Human reads filtering : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> Human reads filtering : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#############################################\n###     Human read filtering : [DONE]     ###\n#############################################\n" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#####################################################\n###     Human read filtering steps is omitted     ###\n#####################################################\n" ; fi

fi

#=======================================================================================================
#
# MERGED PAIRED-END READS
#
#=======================================================================================================

if [[ ${DO_MERGE_READS} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###############################\n###     Merging : [RUN]     ###\n###############################\n" ; fi

	if [[ ${PAIRED} -eq 1 ]] ; then

		mkdir ${OUTPUT}/Reads_merging/

		CMD_BASE="flash ${INPUT_READS} ${INPUT_READS_PAIR2} -r 300 -f 465 -s 47 -o reads -d ${OUTPUT}/Reads_merging/ -t ${THREADS}"

		if [[ ${SGE_METAG} -eq 0 ]] ; then

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
			echo ${CMD_BASE} >> ${OUTPUT}/mgx-seq16S-metagenomics.reads_merging.log
			eval ${CMD_BASE} >> ${OUTPUT}/mgx-seq16S-metagenomics.reads_merging.log 2>&1

		else

			CMD_SGE="${SGE_PREFIX_WAIT_THREADS} -o ${OUTPUT}/mgx-seq16S-metagenomics.reads_merging.log ${CMD_BASE}"
			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
			eval ${CMD_SGE}

		fi

			# -r : read length
			# -f : fragment length (V3V4 by default : position 341/806 on E.coli reference [806-341=465])
			# -s : fragment length standard deviation (if unknown set to 10% of fragment length [10% of 465 = 47])
			# -o : output prefix
			# -d : output directory
			# -t : threads number

		NOT_MERGED_READS1="${OUTPUT}/Reads_merging/reads.notCombined_1.fastq"
		NOT_MERGED_READS2="${OUTPUT}/Reads_merging/reads.notCombined_2.fastq"
		MERGED_READS="${OUTPUT}/Reads_merging/reads.extendedFrags.fastq"

		cat ${NOT_MERGED_READS1} ${NOT_MERGED_READS2} ${MERGED_READS} > "${OUTPUT}/Reads_merging/${READS_BASENAME}.merged.fastq"

		INPUT_READS="${OUTPUT}/Reads_merging/${READS_BASENAME}.merged.fastq"

		PAIRED=0

	fi

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n################################\n###     Merging : [DONE]     ###\n################################\n" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#########################################\n###     Merging steps are omitted     ###\n#########################################\n" ; fi

fi

#=======================================================================================================
#
# MAP READS IN PARALLEL ONTO THE REFERENCE DATABASES
#
#=======================================================================================================

source ${CONF}

# DEFINE PAIR_SEPARATOR VARIABLE
whichPairsSeparator ${INPUT_READS}

SGE=0 # for launch launchAligner in mapping.sh

if [[ ${DO_MAPPING} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###############################\n###     Mapping : [RUN]     ###\n###############################\n" ; fi

	EACH_STEP_FOR_METAG=1

	while [[ ${EACH_STEP_FOR_METAG} -le ${TOT_STEP_MAPPING_METAG} ]]
	do

		if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "### Mapping step # ${EACH_STEP_FOR_METAG}\n" ; fi

		MAPPING_METAG_STEP=$(( ${EACH_STEP_FOR_METAG} - 1 ))
		OUTPUT_MAPPING=${OUTPUT_TMP}/${OUTPUT_MAPPING_TABLE[ ${MAPPING_METAG_STEP} ]}

		if [[ ! -d ${OUTPUT_MAPPING} && ${WRITE_TMP} -eq 0 ]] ; then
			mkdir ${OUTPUT_MAPPING}
		fi

		## FILENAME FOR MAPPING MANAGEMENT
		if [[ ${EACH_STEP_FOR_METAG} -eq 1 ]] ; then
			INPUT_READS_MAPPING=${INPUT_READS}
			INPUT_READS_PAIR2_MAPPING=${INPUT_READS_PAIR2}
		else

			if [[ ${SEQUENTIAL_MAPPING_METAG} -eq 0 ]] ; then

				INPUT_READS_MAPPING=${INPUT_READS}
				INPUT_READS_PAIR2_MAPPING=${INPUT_READS_PAIR2}

			else ############################################################# NOT WORKING AT ALL ####################################

				STEP_TO_REPEAT=step${TOT_STEP}
				NUMBER_STEP_TO_REPEAT=$(( ${MAPPING_METAG_STEP} - 1 ))
				STEP_PATTERN=$( for( (i=1 ; i<=${NUMBER_STEP_TO_REPEAT} ; i++) ) ; do printf "%s" "${STEP_TO_REPEAT}." ; done ; printf "\n" )
				INPUT_READS_DIR_MAPPING=${OUTPUT_TMP}/${OUTPUT_MAPPING_TABLE[ $(( ${MAPPING_METAG_STEP} - 1 )) ]}
				INPUT_READS_MAPPING=${INPUT_READS_DIR_MAPPING}/${READS_BASENAME}.${STEP_PATTERN}fastq

				if [[ ${PAIRED} -eq 1 ]] ; then INPUT_READS_PAIR2_MAPPING=${INPUT_READS_DIR_MAPPING}/${READS_BASENAME_PAIR2}.${STEP_PATTERN}fastq ; fi

			fi

		fi

		## create a tmp configuration file with the right reference db for mapping.sh
		cp ${CONF} ${CONF}.${MAPPING_METAG_STEP}.tmp

		## add other mappers in ulterior versions
		EACH_STEP=1

		while [[ ${EACH_STEP} -le ${TOT_STEP} ]]
		do

			EACH_STEP_FOR_MAPPER=$(( ${EACH_STEP} - 1 ))

			case ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} in

				bwa-sw)
					echo BWASW_REF_DB=${REF_DB_TABLE_BWASW[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa-paired)
					echo BWA_REF_DB=${REF_DB_TABLE_BWA[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa)
					echo BWA_REF_DB=${REF_DB_TABLE_BWA[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa-mem)
					echo BWAMEM_REF_DB=${REF_DB_TABLE_BWAMEM[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa-mem-paired)
					echo BWAMEM_REF_DB=${REF_DB_TABLE_BWAMEM[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				bowtie2)
					echo BOWTIE2_REF_DB=${REF_DB_TABLE_BOWTIE2[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				bowtie2-paired)
					echo BOWTIE2_REF_DB=${REF_DB_TABLE_BOWTIE2[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				tmap)
					echo TMAP_REF_DB=${REF_DB_TABLE_TMAP[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				tmap-paired)
					echo TMAP_REF_DB=${REF_DB_TABLE_TMAP[ ${MAPPING_METAG_STEP} ]} >> ${CONF}.${MAPPING_METAG_STEP}.tmp
				;;

				*)
					echo "Unrecognized mapper : ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} => abort"
					exit 1
				;;

			esac

			EACH_STEP=$(( ${EACH_STEP} + 1 ))

		done

		sleep 5

		# SINGLE-END DATA
		if [[ ${PAIRED} -eq 0 ]] ; then
			CMD_BASE="mgx-seq-mapping.sh -c ${CONF}.${MAPPING_METAG_STEP}.tmp -i ${INPUT_READS_MAPPING} -o ${OUTPUT_MAPPING}"
		else # PAIRED-END DATA
			CMD_BASE="mgx-seq-mapping.sh -c ${CONF}.${MAPPING_METAG_STEP}.tmp -i ${INPUT_READS_MAPPING} -I ${INPUT_READS_PAIR2_MAPPING} -o ${OUTPUT_MAPPING}"
		fi

		if [[ ${SGE_METAG} -eq 0 ]] ; then

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
			echo ${CMD_BASE} > ${OUTPUT}/mgx-seq16S-metagenomics.step${MAPPING_METAG_STEP}.log
			eval ${CMD_BASE} >> ${OUTPUT}/mgx-seq16S-metagenomics.step${MAPPING_METAG_STEP}.log 2>&1

		else ## SGE mode is managed by mgx-seq-mapping.sh and SGE option

			if [[ ${SEQUENTIAL_MAPPING_METAG} -eq 1 ]] ; then

				CMD_SGE="${SGE_PREFIX_WAIT_THREADS} -o ${OUTPUT}/mgx-seq16S-metagenomics.step${MAPPING_METAG_STEP}.log ${CMD_BASE}"
				if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
				eval ${CMD_SGE}

			else

				CMD_SGE="${SGE_PREFIX_THREADS} -o ${OUTPUT}/mgx-seq16S-metagenomics.step${MAPPING_METAG_STEP}.log ${CMD_BASE}"
				if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi

				#run the jobid and retrieve the job id number
				jobIDTable[${MAPPING_METAG_STEP}]=$( SGE_jobid ${CMD_SGE} )
				echo -e "JOB ${jobIDTable[${MAPPING_METAG_STEP}]} has been lauched\n"
				jobIDrun[${MAPPING_METAG_STEP}]=1

			fi
		fi

		EACH_STEP_FOR_METAG=$(( ${EACH_STEP_FOR_METAG} + 1 ))

	done

	## If parallel SGE running mode, check when SGE jobs are finished before ending the script to check when SGE will be ok
	if [[ ${SGE_METAG} -eq 1 && ${SEQUENTIAL_MAPPING_METAG} -eq 0 ]] ; then

		NB_JOBS_ENDED=0
		NB_JOBS_LAUNCHED=${#jobIDTable[@]}

		while [[ ${NB_JOBS_ENDED} -lt ${NB_JOBS_LAUNCHED} ]] ; do

			for (( INDEX=0 ; INDEX<${NB_JOBS_LAUNCHED} ; INDEX++ ))
			do

				SGE_jobid_run ${jobIDTable[${INDEX}]}

				if [[ $? -eq 0 ]] ; then

					if [[ ${jobIDrun[${INDEX}]} -eq 1 ]]; then
						NB_JOBS_ENDED=$(( ${NB_JOBS_ENDED} + 1 ))
						jobIDrun[ ${INDEX} ]=0
					fi

				fi

			done

			sleep 5

		done

		# Here, all jobs have finished
		# Now, test if all jobs are successfully completed
		#sleep 10
		#successful_jobs_SGE ${jobIDTable[@]}

	fi

	sleep 10

	## If outputs file are written in the tmp directory, we have to move them in the desired directory
	if [[ ${WRITE_TMP} -eq 1 && ${SGE_METAG} -eq 1 ]] ; then

		## mv secureMetag tmp directory to output
		CMD_BASE="mv ${OUTPUT_TMP} ${OUTPUT}"
		CMD_SGE="${SGE_PREFIX_THREADS} -o ${OUTPUT}/mgx-seq16S-metagenomics.moving.log ${CMD_BASE}"

		if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo ${CMD_SGE} ; fi

		jobID=$( SGE_jobid ${CMD_SGE} )
		NB_JOBS_ENDED=0

		while [[ ${NB_JOBS_ENDED} -lt 1 ]] ; do

			SGE_jobid_run ${jobID}

			if [[ $? -eq 0 ]] ; then

				NB_JOBS_ENDED=$(( ${NB_JOBS_ENDED} + 1 ))

			fi

		done

		sleep 10

		## when writing in a tmp directory on bertha, rename the output directories
		mv ${OUTPUT}/${OUTPUT_SECUREMETAG_TMP}/* ${OUTPUT}
		rm -rf ${OUTPUT}/${OUTPUT_SECUREMETAG_TMP}

	fi

	if [[ ${SGE_METAG} -eq 1 && ${VERBOSE_METAG} -eq 1 ]] ; then echo "### SGE mapping jobs are finished" ; fi

	echo -e "> Mapping against databases : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> Mapping against databases : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n################################\n###     Mapping : [DONE]     ###\n################################\n" ; fi

else ## ommiting mapping step

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#########################################\n###     Mapping steps are omitted     ###\n#########################################\n" ; fi

fi

#=======================================================================================================
#
# MERGE BAM FILES IF NECESSARY
#
#=======================================================================================================

if [[ ${DO_BAM_MERGE} -eq 1 ]] ; then

	## List all the BAM files to merge

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###################################\n###     BAM Merging : [RUN]     ###\n###################################\n" ; fi

	rm -Rf ${OUTPUT}/bamsToMerge.txt

	EACH_STEP_FOR_METAG=1

	while [[ ${EACH_STEP_FOR_METAG} -le ${TOT_STEP_MAPPING_METAG} ]]
	do

		MAPPING_METAG_STEP=$(( ${EACH_STEP_FOR_METAG} - 1 ))
		OUTPUT_MAPPING=${OUTPUT}/${OUTPUT_MAPPING_TABLE[$MAPPING_METAG_STEP]}

		########################################################################

		# 16S SPECIFIC !

		# if mapper is bwa mem paired
		# TODO : handle case where several mappers are choosed at once
		# if [[ ${nameOFmappers} == "bwa-mem-paired" ]] ; then

			########################################################################
			# # Rewrite bam
			#
			# SRC_DIR="/Projets/PRG0023-Technology_Research_Program/B2723-Identification_and_Detection/Studies/WP2-Samba-Metagenomic/WP2.2-Stools/20-MiSeq_16S_V3V4_dataset_simulation/src/"
			# ${SRC_DIR}/rewrite_bam.sh -i ${OUTPUT_MAPPING}/filtered.bam -o ${OUTPUT_MAPPING}/ #output : ${OUTPUT_MAPPING}/filtered.rewrited.bam
			#
			########################################################################
			# # Option 1 : keep only alignments where both reads of each pair mapped on same reference
			#
			# # GET HEADER AND ALIGNMENTS OF PAIR READS MAPPED ON SAME REFERENCE
			# samtools view -H $( ls ${OUTPUT_MAPPING}/*.step*.sorted.bam ) > ${OUTPUT_MAPPING}/filtered.sam
			#
			# samtools view $( ls ${OUTPUT_MAPPING}/*.step*.sorted.bam ) | awk '{ if ($7 == "=") print $0 }' >> ${OUTPUT_MAPPING}/filtered.sam
			#
			# samtools view -b ${OUTPUT_MAPPING}/filtered.sam > ${OUTPUT_MAPPING}/filtered.bam
			#
			# ########################################################################
			# # Option 2 : keep only both read common alignments for each pair
			#
			# NEW_SRC_DIR="/Projets/PRG0023-Technology_Research_Program/B2723-Identification_and_Detection/Studies/WP2-Samba-Metagenomic/WP2.2-Stools/20-MiSeq_16S_V3V4_dataset_simulation/src/"
			#
			# CMD_BASE="${NEW_SRC_DIR}/bam_common_hits.sh -i $( ls ${OUTPUT_MAPPING}/*.step*.sorted.bam ) -o ${OUTPUT_MAPPING}/ >> ${OUTPUT}/mgx-seq16S-metagenomics.bam_filtering.log" # output : ${OUTPUT_MAPPING}/filtered.bam
			# CMD_SGE="${SGE_PREFIX_WAIT_THREADS} -o ${OUTPUT}/mgx-seq16S-metagenomics.bam_filtering.log ${CMD_BASE}"
			#
			# if [[ ${SGE_METAG} -eq 0 ]] ; then
			# 	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
			# 	eval ${CMD_BASE}
			# else
			# 	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
			# 	eval ${CMD_SGE}
			# fi
			#
			########################################################################

			# echo $( ls ${OUTPUT_MAPPING}/filtered.rewrited.bam ) >> ${OUTPUT}/bamsToMerge.txt
			# echo $( ls ${OUTPUT_MAPPING}/filtered.bam ) >> ${OUTPUT}/bamsToMerge.txt

			########################################################################

		# else # Mapper other than bwa-mem-paired
			echo $( ls ${OUTPUT_MAPPING}/*.step*.sorted.bam ) >> ${OUTPUT}/bamsToMerge.txt
		# fi

		EACH_STEP_FOR_METAG=$(( ${EACH_STEP_FOR_METAG} + 1 ))

	done

	## Create a file with the names of the reads sorted in the same order as samtools sort.
	## To do that, we use the corresponding sorted sam.
	## We assume that the mapper outputs at least 1 line per read

	FIRST_SORTED_BAM=$( ls ${OUTPUT_MAPPING}/*.step*.sorted.bam )

	# SINGLE-END DATA
	if [[ ${PAIRED} -eq 0 ]] ; then

		CMD_BASE="mgx-seq-baminfo -i ${FIRST_SORTED_BAM} -o ${OUTPUT}/${READS_BASENAME}_allReads.txt --unique_name"

		if [[ ${SGE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}\n" ; eval "${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}" ; else echo -e "> Commande : ${CMD_BASE}\n" ; eval ${CMD_BASE} ; fi

		if [[ ${nameOFmappers[0]} == "bwa" ]] ; then
			CMD_BASE="mgx-seq-bam2bh -i ${OUTPUT}/bamsToMerge.txt -r ${OUTPUT}/${READS_BASENAME}_allReads.txt -o ${OUTPUT}/${READS_BASENAME}_allBestHit.txt -a 1 ${BAM2BH_OPTIONS}"
		else
			CMD_BASE="mgx-seq-bam2bh -i ${OUTPUT}/bamsToMerge.txt -r ${OUTPUT}/${READS_BASENAME}_allReads.txt -o ${OUTPUT}/${READS_BASENAME}_allBestHit.txt ${BAM2BH_OPTIONS}"
		fi

		if [[ ${SGE_METAG} -eq 1 ]] ; then

			CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n> Commande : ${CMD_SGE}\n" ; fi
			eval ${CMD_SGE}

		else

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n> Commande : ${CMD_BASE}\n" ; fi
			eval ${CMD_BASE}

		fi

	else # PAIRED-END DATA

		if [[ ${nameOFmappers[0]} == "tmap-paired" ]] ; then

			if [[ ${PAIR_SEPARATOR} == '/' ]] ; then

				CMD_BASE="mgx-seq-baminfo -i ${FIRST_SORTED_BAM} --unique_name | sed '\/2$/d' > ${OUTPUT}/${READS_BASENAME}_allReads.txt"

				if [[ ${SGE_METAG} -eq 1 ]] ; then

					CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
					eval "${CMD_SGE}"

				else

					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
					eval ${CMD_BASE}

				fi

				CMD_BASE="mgx-seq-bam2bh -i ${OUTPUT}/bamsToMerge.txt -r ${OUTPUT}/${READS_BASENAME}_allReads.txt -o ${OUTPUT}/${READS_BASENAME}_allBestHit.txt -s "/" ${BAM2BH_OPTIONS}"

				if [[ ${SGE_METAG} -eq 1 ]] ; then

					CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
					eval "${CMD_SGE}"

				else

					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
					eval ${CMD_BASE}

				fi

			else

				CMD_BASE="mgx-seq-baminfo -i ${FIRST_SORTED_BAM} -o ${OUTPUT}/${READS_BASENAME}_allReads.txt --unique_name"

				if [[ ${SGE_METAG} -eq 1 ]] ; then

					CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
					eval "${CMD_SGE}"

				else

					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
					eval ${CMD_BASE}

				fi

				CMD_BASE="mgx-seq-bam2bh -i ${OUTPUT}/bamsToMerge.txt -r ${OUTPUT}/${READS_BASENAME}_allReads.txt -o ${OUTPUT}/${READS_BASENAME}_allBestHit.txt ${BAM2BH_OPTIONS}"

				if [[ ${SGE_METAG} -eq 1 ]] ; then

					CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
					eval "${CMD_SGE}"

				else

					if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
					eval ${CMD_BASE}

				fi

			fi

		else # OTHER MAPPER THAN TMAP-PAIRED

			CMD_BASE="mgx-seq-baminfo -i ${FIRST_SORTED_BAM} -o ${OUTPUT}/${READS_BASENAME}_allReads.txt --unique_name"

			if [[ ${SGE_METAG} -eq 1 ]] ; then

				CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
				if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
				eval "${CMD_SGE}"

			else

				if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
				eval ${CMD_BASE}

			fi

			if [[ ${nameOFmappers[0]} == "bwa-paired" ]] ; then
				CMD_BASE="mgx-seq-bam2bh -i ${OUTPUT}/bamsToMerge.txt -r ${OUTPUT}/${READS_BASENAME}_allReads.txt -o ${OUTPUT}/${READS_BASENAME}_allBestHit.txt -a 1 ${BAM2BH_OPTIONS}"
			else
				CMD_BASE="mgx-seq-bam2bh -i ${OUTPUT}/bamsToMerge.txt -r ${OUTPUT}/${READS_BASENAME}_allReads.txt -o ${OUTPUT}/${READS_BASENAME}_allBestHit.txt ${BAM2BH_OPTIONS}"
			fi

			if [[ ${SGE_METAG} -eq 1 ]] ; then

				CMD_SGE="${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"
				if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi
				eval "${CMD_SGE}"

			else

				if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
				eval ${CMD_BASE}

			fi

		fi
	fi

	echo -e "> BAM files merging : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> BAM files merging : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n####################################\n###     BAM Merging : [DONE]     ###\n####################################\n" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###########################################\n###     BAM merging step is omitted     ###\n###########################################\n" ; fi


fi

#=======================================================================================================
#
# LCA
#
#=======================================================================================================

if [[ ${DO_LCA} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###########################\n###     LCA : [RUN]     ###\n###########################\n" ; fi

	## Creating the input map file
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo "### Creating the input map file ... " ; fi
	NB_INPUT_MAP=${#INPUT_MAP_TABLE[@]}
	cat ${INPUT_MAP_TABLE[@]} > ${OUTPUT}/inputMap.txt
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "[ DONE ]\n" ; fi

	## Transform gi into taxids
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "### Converting gi into taxids...\n" ; fi
	CMD_BASE="mgx-taxo-gi2tax -o ${OUTPUT}/${READS_BASENAME}_allBestHitTaxid.txt -m ${OUTPUT}/inputMap.txt -q ${OUTPUT}/${READS_BASENAME}_allBestHit.txt"
	if [[ ${SGE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}\n" ; eval "${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}"; else echo -e "> Commande : ${CMD_BASE}\n" ; eval ${CMD_BASE} ; fi
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n[ DONE ]\n" ; fi

	## finding LCA
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "### Retrieving LCA...\n" ; fi
	CMD_BASE="mgx-taxo-lca -i ${OUTPUT}/${READS_BASENAME}_allBestHitTaxid.txt -o ${OUTPUT}/${READS_BASENAME}_LCA.txt -t ${TAXO_DB}"
	if [[ ${SGE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}\n" ; eval "${SGE_PREFIX_WAIT} -o /dev/null ${CMD_BASE}" ; else echo -e "> Commande : ${CMD_BASE}\n" ; eval ${CMD_BASE} ; fi
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n[ DONE ]\n" ; fi

	## creating metag file
	perl -e 'my %hash1 = (); my %hash2 = (); $file_name = "'$READS_BASENAME'"; while ($ligne = <>){ chomp( $ligne ); @tab = split( /\t/, $ligne ); $hash1{ $tab[1] } = "$tab[2]\t$tab[3]"; if ( exists $hash2{ $tab[1] } ) { $hash2{ $tab[1] } = $hash2{ $tab[1] } + 1; } else { $hash2{ $tab[1] } = 1; } } foreach $taxid (keys(%hash1)){ print $file_name, "\t", $taxid, "\t", $hash1{ $taxid }, "\t", $hash2{ $taxid }, "\n"; }' ${OUTPUT}/${READS_BASENAME}_LCA.txt > ${OUTPUT}/${READS_BASENAME}_allBestHit_metag.txt

	LINE_NUMBER=$( cat ${OUTPUT}/${READS_BASENAME}_allBestHit_metag.txt | wc -l )

	# COUNT MAPPED READS
	if [[ ${LINE_NUMBER} -gt 0 ]] ; then
		COUNT_MAPPED_READ=$( cat ${OUTPUT}/${READS_BASENAME}_allBestHit_metag.txt | awk -F'\t' '{ SUM += $5 } END { print SUM }' )
	else
		COUNT_MAPPED_READ=0
	fi


	#=======================================================================================================
	#
	# GZIP OUTPUT FILES
	#
	#=======================================================================================================

	if [[ ${SGE_METAG} -eq 0 ]] ; then
		gzip ${OUTPUT}/${READS_BASENAME}_LCA.txt
		gzip ${OUTPUT}/${READS_BASENAME}_allBestHitTaxid.txt
		gzip ${OUTPUT}/${READS_BASENAME}_allBestHit.txt
	fi

	if [[ ${SGE_METAG} -eq 1 ]] ; then
		${SGE_PREFIX_WAIT} -o /dev/null gzip ${OUTPUT}/${READS_BASENAME}_LCA.txt
		${SGE_PREFIX_WAIT} -o /dev/null gzip ${OUTPUT}/${READS_BASENAME}_allBestHitTaxid.txt
		${SGE_PREFIX_WAIT} -o /dev/null gzip ${OUTPUT}/${READS_BASENAME}_allBestHit.txt
	fi

	echo -e "> LCA : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> LCA : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###########################\n###     LCA : [DONE]     ###\n###########################\n" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###################################\n###     LCA step is omitted     ###\n###################################\n" ; fi

fi

#=======================================================================================================
#
# GZIP INPUT FILE
#
#=======================================================================================================

if [[ GZ_BOOL_METAG -eq 1 ]] ; then

	# SINGLE-END DATA
	if [[ ${PAIRED} -eq 0 ]] ; then

		if [[ ${SGE_METAG} -eq 0 ]] ; then
			gzip ${INITIAL_FASTQ_1}
		fi

		if [[ ${SGE_METAG} -eq 1 ]] ; then
			${SGE_PREFIX_WAIT} -o /dev/null gzip ${INITIAL_FASTQ_1}
		fi

	else # PAIRED-END DATA

		if [[ ${SGE_METAG} -eq 0 ]] ; then
			gzip ${INITIAL_FASTQ_1}
			gzip ${INITIAL_FASTQ_2}
		fi

		if [[ ${SGE_METAG} -eq 1 ]] ; then
			${SGE_PREFIX_WAIT} -o /dev/null gzip ${INITIAL_FASTQ_1}
			${SGE_PREFIX_WAIT} -o /dev/null gzip ${INITIAL_FASTQ_2}
		fi

	fi
fi

#=======================================================================================================
#
# REMOVE INTERMEDIATE FASTQ FILES (QC AND HUMAN FILTERING)
#
#=======================================================================================================

if [[ ${CLEANING} -eq 1 ]] ; then

	if [[ ${DO_FILTERING_QC} -eq 1 ]] ; then

		# SINGLE-END DATA
		if [[ ${PAIRED} -eq 0 ]] ; then
			rm ${CLEAN_FASTQ_QC}
		else # PAIRED-END DATA
			rm ${CLEAN_FASTQ_QC_PAIR1}
			rm ${CLEAN_FASTQ_QC_PAIR2}
			if [[ -e ${CLEAN_FASTQ_QC_SGL} ]] ; then rm ${CLEAN_FASTQ_QC_SGL} ; fi
		fi

	fi

	if [[ ${DO_HOST_FILTERING} -eq 1 ]] ; then

		# SINGLE-END DATA
		if [[ ${PAIRED} -eq 0 ]] ; then
			rm ${CLEAN_FASTQ_HOST_FILTER}
		else # PAIRED-END DATA
			rm ${CLEAN_FASTQ_HOST_FILTER_PAIR1}
			rm ${CLEAN_FASTQ_HOST_FILTER_PAIR2}
		fi

	fi

fi

#=======================================================================================================
#
# SUMMARY
#
#=======================================================================================================

if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#######################\n###     Summary     ###\n#######################\n" ; fi

echo -e "> Number of reads in fastq : ${TOTAL_READ_COUNT}"
echo -e "> Number of reads in fastq : ${TOTAL_READ_COUNT}" >> ${OUTPUT}/summary.txt

# FILTERING QC YES
if [[ ${DO_FILTERING_QC} -eq 1 ]] ; then
	echo -e "> Number of reads after QC filtering : ${COUNT_READ_AFTER_QC} ($(( ${TOTAL_READ_COUNT} - ${COUNT_READ_AFTER_QC} )) reads discarded)"
	echo -e "> Number of reads after QC filtering : ${COUNT_READ_AFTER_QC} ($(( ${TOTAL_READ_COUNT} - ${COUNT_READ_AFTER_QC} )) reads discarded)" >> ${OUTPUT}/summary.txt

	# FILTERING QC YES, FILTERING HOST YES
	if [[ ${DO_HOST_FILTERING} -eq 1 ]] ; then
		echo -e "> Number of reads after human filtering : ${COUNT_READ_AFTER_HUMAN_FILTERING} ($(( ${COUNT_READ_AFTER_QC} - ${COUNT_READ_AFTER_HUMAN_FILTERING} )) reads discarded)"
		echo -e "> Number of reads after human filtering : ${COUNT_READ_AFTER_HUMAN_FILTERING} ($(( ${COUNT_READ_AFTER_QC} - ${COUNT_READ_AFTER_HUMAN_FILTERING} )) reads discarded)" >> ${OUTPUT}/summary.txt

		# FILTERING QC YES, FILTERING HOST YES, MAPPING, BAM MERGE AND LCA YES
		if [[ ${DO_MAPPING} -eq 1 && ${DO_BAM_MERGE} -eq 1 && ${DO_LCA} -eq 1 ]] ; then
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${COUNT_READ_AFTER_HUMAN_FILTERING} - ${COUNT_MAPPED_READ} )) reads discarded)"
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${COUNT_READ_AFTER_HUMAN_FILTERING} - ${COUNT_MAPPED_READ} )) reads discarded)" >> ${OUTPUT}/summary.txt
		fi

	else # FILTERING QC YES, FILTERING HOST NO

		# FILTERING QC YES, FILTERING HOST NO, MAPPING, BAM MERGE AND LCA YES
		if [[ ${DO_MAPPING} -eq 1 && ${DO_BAM_MERGE} -eq 1 && ${DO_LCA} -eq 1 ]] ; then
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${COUNT_READ_AFTER_QC} - ${COUNT_MAPPED_READ} )) reads discarded)"
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${COUNT_READ_AFTER_QC} - ${COUNT_MAPPED_READ} )) reads discarded)" >> ${OUTPUT}/summary.txt

		fi

	fi

else # FILTERING QC NO

	# FILTERING QC NO, FILTERING HOST YES
	if [[ ${DO_HOST_FILTERING} -eq 1 ]] ; then
		echo -e "> Number of reads after human filtering : ${COUNT_READ_AFTER_HUMAN_FILTERING} ($(( ${TOTAL_READ_COUNT} - ${COUNT_READ_AFTER_HUMAN_FILTERING} )) reads discarded)"
		echo -e "> Number of reads after human filtering : ${COUNT_READ_AFTER_HUMAN_FILTERING} ($(( ${TOTAL_READ_COUNT} - ${COUNT_READ_AFTER_HUMAN_FILTERING} )) reads discarded)" >> ${OUTPUT}/summary.txt

		# FILTERING QC NO, FILTERING HOST YES, MAPPING, BAM MERGE AND LCA YES
		if [[ ${DO_MAPPING} -eq 1 && ${DO_BAM_MERGE} -eq 1 && ${DO_LCA} -eq 1 ]] ; then
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${COUNT_READ_AFTER_HUMAN_FILTERING} - ${COUNT_MAPPED_READ} )) reads discarded)"
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${COUNT_READ_AFTER_HUMAN_FILTERING} - ${COUNT_MAPPED_READ} )) reads discarded)" >> ${OUTPUT}/summary.txt

		fi

	else # FILTERING QC NO, FILTERING HOST NO

		# FILTERING QC NO, FILTERING HOST NO, MAPPING, BAM MERGE AND LCA YES
		if [[ ${DO_MAPPING} -eq 1 && ${DO_BAM_MERGE} -eq 1 && ${DO_LCA} -eq 1 ]] ; then
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${TOTAL_READ_COUNT} - ${COUNT_MAPPED_READ} )) reads discarded)"
			echo -e "> Number of mapped reads : ${COUNT_MAPPED_READ} ($(( ${TOTAL_READ_COUNT} - ${COUNT_MAPPED_READ} )) reads discarded)" >> ${OUTPUT}/summary.txt
		fi

	fi

fi

if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n[ THE END ]\n" ; fi

#=======================================================================================================
#
# STOPING TIMER
#
#=======================================================================================================

echo -e "\nTotal running time for mgx-seq16S-metagenomics.sh : $( gettime ${METAG_TIME} ) (minutes:secondes)"

echo -e "\nEND MGX-SEQ16S-METAGENOMICS\n"

exit 0

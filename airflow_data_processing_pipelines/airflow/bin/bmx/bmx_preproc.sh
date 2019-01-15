#!/bin/bash
source /mnt/gpfs/pt6/airflow/bin/bmx/bash_functions.lib

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

#echo "pengfei_test" >> ${CONF}

#=======================================================================================================
#
# LOAD CONFIGURATION FILE
#
#=======================================================================================================

source ${CONF}

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
echo $INPUT_READS
echo $INPUT_READS_PAIR2
		for MAP in ${SE_MAPPERS}
		do
			if [[ ${nameOFmappers} == ${MAP} ]] ; then SE_MAPPER_OK=1 ; fi #SE_MAPPER_OK PASSE A 1 SI ON A UN BON MAPPER
		done

		if [[ ${SE_MAPPER_OK} -eq 0 ]] ; then echo "${nameOFmappers} : bad mapper for MERGED (single-end) reads" ; exit 0 ; fi

	fi

fi


# OUTPUT EXISTS
if [[ ! -d ${OUTPUT}/Preprocessing/ ]] ; then
	mkdir -p ${OUTPUT}/Preprocessing/
    mkdir -p ${OUTPUT}/Rawdata/
fi

# TRIM READ FILE PATH AND NAME
EXTENSION="fastq"
READS_FILENAME=$( basename ${INPUT_READS} )                 ## with the extension
READS_BASENAME=$( basename ${INPUT_READS%.*} )  ## without the extention
READS_DIRNAME=$(dirname ${INPUT_READS})                   ## directory without the final slash

# TRIM READ FILE PATH AND NAME FOR PAIRED DATA IF NECESSARY
if [[ ${PAIRED} -eq 1 ]] ; then
    READS_FILENAME_PAIR2=$( basename ${INPUT_READS_PAIR2} )
    READS_BASENAME_PAIR2=$( basename ${INPUT_READS_PAIR2%.*} )
fi


# DETERMINE GZIP STATUS FROM READ FILE EXTENSION AND UNGZIP IF NECESSARY
if [[ ${GZ_BOOL_METAG} -eq 1 ]] ; then

	if [[ ${SGE_METAG} -eq 0 ]] ; then
		gunzip -c ${INPUT_READS} > ${OUTPUT}/Rawdata/${READS_BASENAME%.gz}
	fi

	INPUT_READS=${OUTPUT}/Rawdata/${READS_BASENAME%.gz}

	if [[ ${PAIRED} -eq 1 ]] ; then

		if [[ ${SGE_METAG} -eq 0 ]] ; then
			gunzip -c ${INPUT_READS_PAIR2} > ${OUTPUT}/Rawdata/${READS_BASENAME_PAIR2%.gz}
		fi

		INPUT_READS_PAIR2=${OUTPUT}/Rawdata/${READS_BASENAME_PAIR2%.gz}

	fi
fi

# GET INITIAL FASTQ PATH TO GZIP AT THE END
INITIAL_FASTQ_1=${INPUT_READS}
if [[ ${PAIRED} -eq 1 ]] ; then INITIAL_FASTQ_2=${INPUT_READS_PAIR2} ; fi

# DEFINE THE TMP DIRECTORY TO WRITE PIPELINE OUTPUTS IN THE TMP DIRECTORY

OUTPUT_TMP=${OUTPUT}

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
METAG_TIME=${SECONDS}

if [[ ${DO_FILTERING_QC} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#######################################\n###     Filtering and QC: [RUN]     ###\n#######################################\n" ; fi

	# SINGLE-END DATA
	if [[ ${PAIRED} -eq 0 ]] ; then

		READ_COUNT=$( fqsize ${INPUT_READS} )

		echo -e "> Number of reads before QC step : ${READ_COUNT}\n"
		echo "Number of reads before QC step : ${READ_COUNT}" > ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log

		# MISEQ PREPROC NOT AVAILABLE WITH SINGLE END DATA --> THREAD=1
		CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -x ${OUTPUT}/${READS_BASENAME}.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -a 1"
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
#add by pengfei
echo "COUNT_READ_AFTER_QC="${COUNT_READ_AFTER_QC} >> ${CONF}

		if [[ ! -s ${INPUT_READS} ]] ; then
			echo "Filtered reads file is empty => abort"
			exit 1
		fi

		READS_FILENAME=$( basename ${INPUT_READS} )                 ## with the extension
		READS_BASENAME=$(basename ${INPUT_READS%.*}) ## without the extention
		READS_DIRNAME=$(dirname ${INPUT_READS})                   ## directory without the final slash

	else # PAIRED-END DATA
		READ_COUNT=$( fqsize ${INPUT_READS} )
echo ${INPUT_READS}
		echo -e "> Number of reads before QC step : ${READ_COUNT}\n"
		echo "Number of reads before QC step : ${READ_COUNT}" >> ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log

		if [[ ${DO_MERGE_READS} -eq 1 ]] ; then
			# MISEQ PRPEPROC : YES
			if [[ ${MISEQ_PREPROC} -eq 1 ]] ; then
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/Preprocessing/${READS_BASENAME%.fastq}.filtered.fastq  -y ${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2%.fastq}.filtered.fastq -z ${OUTPUT}/Preprocessing/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -n ${THREADS} -s CMC -c ${CLEANING} -a 0"
			else # MISEQ PREPROC : NO
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/Preprocessing/${READS_BASENAME%.fastq}.filtered.fastq  -y ${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2%.fastq}.filtered.fastq -z ${OUTPUT}/Preprocessing/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -a 0"
			fi
		else
			# MISEQ PRPEPROC : YES
			if [[ ${MISEQ_PREPROC} -eq 1 ]] ; then
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/Preprocessing/${READS_BASENAME%.fastq}.filtered.fastq  -y ${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2%.fastq}.filtered.fastq -z ${OUTPUT}/Preprocessing/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -n ${THREADS} -s CMC -c ${CLEANING} -a 0"
			else # MISEQ PREPROC : NO
				CMD_BASE="fqPreproc.sh -f ${INPUT_READS} -r ${INPUT_READS_PAIR2} -x ${OUTPUT}/Preprocessing/${READS_BASENAME%.fastq}.filtered.fastq  -y ${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2%.fastq}.filtered.fastq -z ${OUTPUT}/Preprocessing/${READS_BASENAME}.singleton.filtered.fastq -q ${QUAL_THRESHOLD} -l ${MIN_READ_LENGTH} -p ${PERCENT_CONFIDENT_BPS} -a 0"
			fi 
		fi

		# MODE SGE : NO
		if [[ ${SGE_METAG} -eq 0 ]] ; then

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n"; fi

			eval ${CMD_BASE} > ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log 2>&1
		else # MODE SGE : YES

			# MISEQ PRPEPROC : YES --> THREADS=${THREADS}
			# if [[ ${MISEQ_PREPROC} -eq 1 ]] ; then
			# 	SGE_PREFIX_1="qsub -sync y -V -b y -j y -P ${PROJECT} -pe smp ${THREADS}"
			# else # MISEQ PRPEPROC : NO --> THREADS=1
			# 	SGE_PREFIX_1="qsub -sync y -V -b y -j y -P ${PROJECT} -pe smp 1"
			# fi

			CMD_SGE="${SGE_PREFIX_1} -o ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log ${CMD_BASE}"

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_SGE}\n" ; fi

			eval ${CMD_SGE}

		fi

		INPUT_READS=${OUTPUT}/Preprocessing/${READS_BASENAME%.fastq}.filtered.fastq
		INPUT_READS_PAIR2=${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2%.fastq}.filtered.fastq

		CLEAN_FASTQ_QC_PAIR1=${INPUT_READS}
		CLEAN_FASTQ_QC_PAIR2=${INPUT_READS_PAIR2}
		CLEAN_FASTQ_QC_SGL="${OUTPUT}/Preprocessing/${READS_BASENAME%.fastq}.singleton.filtered.fastq"

		READ_COUNT=$( fqsize ${INPUT_READS} )
		echo -e "> Number of reads after QC step : ${READ_COUNT}\n"
		echo "Number of reads after QC step : ${READ_COUNT}\n" >> ${OUTPUT}/mgx-seq16S-metagenomics.fqPreproc.log
		COUNT_READ_AFTER_QC=${READ_COUNT}
#add by pengfei
echo "COUNT_READ_AFTER_QC="${COUNT_READ_AFTER_QC} >> ${CONF}

		if [[ ! -s ${INPUT_READS} || ! -s ${INPUT_READS_PAIR2} ]] ; then
			echo "Filtered reads files are empty => abort"
			exit 1
		fi

	fi

	# echo "INPUT_READS="${INPUT_READS} > ${OUTPUT}/source_preproc.conf 
	# echo "INPUT_READS_PAIR2="${INPUT_READS_PAIR2} >> ${OUTPUT}/source_preproc.conf 
	# echo "CLEAN_FASTQ_QC_PAIR1="${CLEAN_FASTQ_QC_PAIR1} >> ${OUTPUT}/source_preproc.conf 
	# echo "CLEAN_FASTQ_QC_PAIR2="${CLEAN_FASTQ_QC_PAIR2} >> ${OUTPUT}/source_preproc.conf 
	# echo "CLEAN_FASTQ_QC_SGL="${CLEAN_FASTQ_QC_SGL} >> ${OUTPUT}/source_preproc.conf 
	# echo "COUNT_READ_AFTER_QC="${COUNT_READ_AFTER_QC} >> ${OUTPUT}/source_preproc.conf 

	# echo "READS_FILENAME="${READS_FILENAME} >> ${OUTPUT}/source_preproc.conf 
	# echo "READS_BASENAME="${READS_BASENAME} >> ${OUTPUT}/source_preproc.conf 
	# echo "READS_DIRNAME="${READS_DIRNAME} >> ${OUTPUT}/source_preproc.conf 
	# echo "READS_FILENAME_PAIR2="${READS_FILENAME_PAIR2} >> ${OUTPUT}/source_preproc.conf 
	# echo "READS_BASENAME_PAIR2="${READS_BASENAME_PAIR2} >> ${OUTPUT}/source_preproc.conf 
	# echo "OUTPUT="${OUTPUT} >> ${OUTPUT}/source_preproc.conf 
	# cat ${OUTPUT}/source_preproc.conf >> ${CONF_PREPROC}

	echo -e "> Filtering & QC : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> Filtering & QC : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n########################################\n###     Filtering and QC: [DONE]     ###\n########################################" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#################################################\n###    Filtering and QC steps are omitted     ###\n#################################################" ; fi

fi

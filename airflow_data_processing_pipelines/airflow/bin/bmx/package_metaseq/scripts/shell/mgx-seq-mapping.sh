#! /bin/bash
## Function that launch 1 mapper against 1 reference DB

echo -e "\nBEGIN MGX-SEQ-MAPPING\n"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================

MAPPING_TIME=${SECONDS}

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

usage() {
cat << EOF
usage: $0 options

This script performs:
	- reads mapping against a reference database. This script supports several mapping steps (sequential or parallel)

DOC:
	A BioTechno documentation of this script is available: http://biopedia.biomerieux.net/biopedia/biotechno/index.php/mapping.sh
	It contains more details than this usage message.

INPUTS:
	-c		Path to configuration file (mandatory)
	-i		Path to input reads file (fastq format) (mandatory)
	-I		Path to input pair2 reads file (fastq format) (optional)
	-o		Path to the output directory (mandatory)

OUTPUTS:
	- BAM(s) or SAM(s) file depending on the mapping options

DEPENDENCIES:
	MIXGENOMIX=/anais/IT/reference/users/maud/ProjetsEclipse/mixgenomix
	SEQUENCING_TOOLS=/Projet/PRG0023-Technology_Research_Program/B1848-Microbial_Sequencing/Tools
	SEQUENCING_TOOLS_SRC=${SEQUENCING_TOOLS}/src
	PATH=$PATH:${MIXGENOMIX}/library/shell
	PATH=$PATH:${MIXGENOMIX}/scripts/shell
	PATH=$PATH:${SEQUENCING_TOOLS_SRC}/samtools-0.1.18/
	export PATH

EOF
}

#=======================================================================================================
#
# Get the program arguments
#
#=======================================================================================================

while getopts "c:i:I:o:" PARAMETERS
do
	case ${PARAMETERS} in 
		
		# Config file
		c) CONF=${OPTARG};;
		
		# Path to the input reads file
		i) INPUT_READS=${OPTARG};;
		
		# Path to the second pairs of reads file
		I) INPUT_READS_PAIR2=${OPTARG};;
		
		# Path to the output directory
		o) OUTPUT=${OPTARG};;

		:) echo " Option -${OPTARG} expects an argument " ; exit ;;

		\?) echo " Unvalid option ${OPTARG} " ; exit ;;

	esac
done

if [[ -z ${CONF} || -z ${INPUT_READS} || -z ${OUTPUT} ]] ; then

	usage
	exit 1

fi

#=======================================================================================================
#
# Load the configuration file
#
#=======================================================================================================
					
source ${CONF}

#=======================================================================================================
#
# USAGE RESTRICTIONS TESTS
#
#=======================================================================================================

if [[ ${PAIRED} -eq 1 && -z ${INPUT_READS_PAIR2} ]] ; then

	echo "You should provide the path to the file of the second pairs of reads"
	exit 1

fi

# OUTPUT exists
if [[ ! -d ${OUTPUT} ]] ; then

	mkdir -p ${OUTPUT}

fi

if [[ ${GZ_BOOL} -eq 1 ]] ; then

	gunzip ${INPUT_READS}
	gunzip ${INPUT_READS_PAIR2}

fi

EXTENSION="fastq"
READS_FILENAME=$( getFilename ${INPUT_READS} ) 					## with the extension
READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} ) 	##without the extention
READS_DIRNAME=$( getDirname ${INPUT_READS} ) 					## directory without the final slash

if [[ ${PAIRED} -eq 1 ]] ; then

	READS_FILENAME_PAIR2=$( getFilename ${INPUT_READS_PAIR2} )
	READS_BASENAME_PAIR2=$( getBasenameExt ${INPUT_READS_PAIR2} ${EXTENSION} )

fi
															
if [[ ${GZ_BOOL} -eq 1 ]] ; then

	INPUT_READS=${READS_DIRNAME}/${READS_BASENAME}.fastq
	INPUT_READS_PAIR2=${READS_DIRNAME}/${READS_BASENAME_PAIR2}.fastq

fi

if [[ ${VERBOSE} -eq 1 ]] ; then 

	echo "The reads file to align is : ${INPUT_READS}"
	echo "The reads file dirname : ${READS_DIRNAME}" 
	echo "The reads file name : ${READS_FILENAME}" 
	echo "The reads file basename : ${READS_BASENAME}" 

	if [ ${PAIRED} -eq 1 ] ; then
		
		echo "The reads file of the second pair to align is : ${INPUT_READS_PAIR2}"
		echo "The reads file name for the second pair is : ${READS_FILENAME_PAIR2}"
		echo "The reads file basename for the second pair is : ${READS_BASENAME_PAIR2}" 

	fi

	echo -e "The output directory is : ${OUTPUT}\n"
fi

#=======================================================================================================
#
# MAP READS ONTO THE REFERENCE DATABASE
#
#=======================================================================================================

EACH_STEP=1

while [ ${EACH_STEP} -le ${TOT_STEP} ]
do	
	
	echo "Step # ${EACH_STEP}"
	
	if [[ ${EACH_STEP} -eq 1 || ${SEQUENTIAL} -eq 0 ]] ; then 
	
		INPUT_DIR_FOR_MAPPER=${READS_DIRNAME}	

	else
		
		INPUT_DIR_FOR_MAPPER=${OUTPUT}

	fi

	EACH_STEP_FOR_MAPPER=$(( $EACH_STEP - 1 ))

	PAIR_SEPARATOR="PAIR_SEPARATOR" # The PAIR_SEPARATOR variable is re-defined in mgx-seq-launchAligner

	case ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} in
		
		bwa-sw)

			echo "mapping with BWA-SW"
			CMD_BASE="mgx-seq-launchAligner.sh ${BWASW_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BWASW_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT}"

		;;
		
		bwa-mem)

			echo "mapping with BWA-MEM"
			CMD_BASE="mgx-seq-launchAligner.sh ${BWAMEM_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BWAMEM_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT}"

		;;
		
		bwa-mem-paired)
		
			echo "mapping with BWA-MEM-PAIRED"

			# echo "1 ${BWAMEM_REF_DB}"
			# echo "2 ${READS_BASENAME}"
			# echo "3 ${INPUT_DIR_FOR_MAPPER}"
			# echo "4 ${OUTPUT}"
			# echo "5 ${EACH_STEP}"
			# echo "6 ${SEQUENTIAL}"
			# echo "7 ${COMPRESS_ALIGNMENT}"
			# echo "8 ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]}"
			# echo "9 ${PAIRED}"
			# echo "10 ${PAIR_SEPARATOR}"
			# echo "11 ${CLEANING}"
			# echo "12 ${VERBOSE}"
			# echo "13 ${THREADS}"
			# echo "14 ${BWAMEM_OPTION}"
			# echo "15 ${SAM_SORT_LEXICO}"
			# echo "16 ${SGE}"
			# echo "17 ${FASTQ_OUT}"
			# echo "18 ${READS_BASENAME_PAIR2}"

			CMD_BASE="mgx-seq-launchAligner.sh ${BWAMEM_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BWAMEM_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT} ${READS_BASENAME_PAIR2}"
		
		;;
		
		bowtie2)
	
			echo "mapping with BOWTIE2"
			CMD_BASE="mgx-seq-launchAligner.sh ${BOWTIE2_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BOWTIE2_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT}"
	
		;;
		
		bowtie2-paired)
		
			echo "mapping with BOWTIE2-PAIRED"
			CMD_BASE="mgx-seq-launchAligner.sh ${BOWTIE2_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BOWTIE2_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT} ${READS_BASENAME_PAIR2}"
	
		;;
		
		tmap)
	
			echo "mapping with TMAP"
			CMD_BASE="mgx-seq-launchAligner.sh ${TMAP_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${TMAP_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT}"
	
		;;
		
		bwa-paired)

			echo "mapping paired reads with bwa-paired"
			CMD_BASE="mgx-seq-launchAligner.sh ${BWA_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BWA_ALN_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT} ${READS_BASENAME_PAIR2} ${BWA_SAMPE_OPTION}"
	
		;;
		
		bwa)

			echo "mapping paired reads with bwa"
			READS_BASENAME_PAIR2=UNUSED_BASENAME_PAIR2
			CMD_BASE="mgx-seq-launchAligner.sh ${BWA_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${BWA_ALN_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT} ${READS_BASENAME_PAIR2} ${BWA_SAMSE_OPTION}"
		
		;;
		
		tmap-paired)

			echo "mapping paired reads with tmap-paired"
			CMD_BASE="mgx-seq-launchAligner.sh ${TMAP_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${TMAP_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT} ${READS_BASENAME_PAIR2}"
		
		;;

		# snap)
		
		# 	echo "mapping with snap"
		# 	CMD_BASE="mgx-seq-launchAligner.sh ${SNAP_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${SNAP_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT}"
		
		# ;;

		# snap-paired)

		# 	echo "mapping paired reads with snap-paired"
		# 	CMD_BASE="mgx-seq-launchAligner.sh ${SNAP_REF_DB} ${READS_BASENAME} ${INPUT_DIR_FOR_MAPPER} ${OUTPUT} ${EACH_STEP} ${SEQUENTIAL} ${COMPRESS_ALIGNMENT} ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} ${PAIRED} ${PAIR_SEPARATOR} ${CLEANING} ${VERBOSE} ${THREADS} ${SNAP_OPTION} ${SAM_SORT_LEXICO} ${SGE} ${FASTQ_OUT} ${READS_BASENAME_PAIR2}"
		
		# ;;

		*)

			echo "Unrecognized mapper : ${MAPPER} => abort"
			exit 1

		;;

	esac


	if [[ ${SGE} -eq 0 ]] ; then

		echo ${CMD_BASE} > ${OUTPUT}/mgx-seq-mapping.${READS_BASENAME}.step${EACH_STEP}.log
		eval ${CMD_BASE} >> ${OUTPUT}/mgx-seq-mapping.${READS_BASENAME}.step${EACH_STEP}.log 2>&1

	else

		CMD_BASE=`echo ${CMD_BASE} | sed -e "s/\"/\\\'\"/1" | sed -e "s/\"/\\\'\"/3" | sed -e "s/\"/\"\\'/2" | sed -e "s/\"/\"\\'/4"`

		if [[ ${SEQUENTIAL} -eq 1 ]] ; then

			# surrounding doubles quotes with simple quotes
			
			SGE_CMD="qsub -sync y -V -b y -pe smp ${THREADS} -j y -o ${OUTPUT}/mgx-seq-mapping.${READS_BASENAME}.step${EACH_STEP}.log "
			
			if [[ ! -z ${PROJECT} ]]; then SGE_CMD+="-P ${PROJECT} "; fi
			
			eval ${SGE_CMD} ${CMD_BASE}
			
		else
			
			SGE_CMD="qsub -sync y -V -b y -pe smp ${THREADS} -j y -o ${OUTPUT}/mgx-seq-mapping.${READS_BASENAME}.step${EACH_STEP}.log "
			
			if [[ ! -z ${PROJECT} ]]; then SGE_CMD+="-P ${PROJECT} "; fi
			
			eval ${SGE_CMD} ${CMD_BASE}

			## run the jobid and retrieve the job id number
			jobIDTable[${EACH_STEP_FOR_MAPPER}]=$( SGE_jobid ${SGE_CMD}${CMD_BASE} )

		fi
	fi
	
	EACH_STEP=$(( $EACH_STEP + 1 ))
	
done

## If parallel SGE running mode, check when SGE jobs are finished before ending the script
if [[ ${SGE} -eq 1 && ${SEQUENTIAL} -eq 0 ]] ; then 

	NB_SGE_ENDED=0
	NB_SGE_LAUNCHED=${#jobIDTable[@]}

	while [ ${NB_SGE_ENDED} -lt ${NB_SGE_LAUNCHED} ]; do 
		
		# timestamp
		TS=$( date +%T )

		if [[ ${VERBOSE} -eq 1 ]] ; then echo "${TS}: begin checking jobs running" ; fi
	
	
		for (( INDEX=0; INDEX<${NB_SGE_LAUNCHED}; INDEX++ ))
		do

			SGE_jobid_run ${jobIDTable[INDEX]}
			
			if [[ $? -eq 0 ]] ; then 
				
				NB_SGE_ENDED=$(( ${NB_SGE_ENDED} + 1 )) 

				if [[ ${VERBOSE} -eq 1 ]] ; then echo "JOB ${jobIDTable[INDEX]} has ended" ; fi

			else
				
				if [[ ${VERBOSE} -eq 1 ]] ; then echo "JOB ${jobIDTable[INDEX]} is still running" ; fi

			fi
		done
  
	sleep 5

	done
fi

#=======================================================================================================
#
# STOPING TIMER
#
#=======================================================================================================

echo -e "\nTotal running time for mgx-seq-mapping.sh : $( gettime ${MAPPING_TIME} ) (minutes:secondes)"

echo -e "\nEND MGX-SEQ-MAPPING\n"
	
exit 0

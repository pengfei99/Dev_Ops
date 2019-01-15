#!/bin/bash
source bash_functions.lib

#=======================================================================================================
#
# GET THE PROGRAMM ARGUMENTS
#
#=======================================================================================================

while getopts "c:i:o:" PARAMETER
do
	case ${PARAMETER} in

		# CONFIG FILE
		c) CONF=${OPTARG};;

		# PATH TO THE INPUT READS FILE
		i) INPUT_READS=${OPTARG};;

		# PATH TO THE OUTPUT DIRECTORY
		o) OUTPUT=${OPTARG};;

		:) echo " Option -${OPTARG} expects an argument " ; exit ;;
		\?) echo " Unvalid option ${OPTARG} " ; exit ;;

	esac
done

#=======================================================================================================
#
# LOAD CONFIGURATION FILE
#
#=======================================================================================================

source ${CONF}

PAIRED=0
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

# Define input reads
READS_BASENAME=$(basename ${INPUT_READS%.fastq}) ## without the extention
INPUT_READS=${OUTPUT}/Reads_merging/${READS_BASENAME}.merged.fastq

OUTPUT_TMP=${OUTPUT}

METAG_TIME=${SECONDS}

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
		CONF_NAME=$(basename ${CONF})
		cp ${CONF} ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp

		## add other mappers in ulterior versions
		EACH_STEP=1

		while [[ ${EACH_STEP} -le ${TOT_STEP} ]]
		do

			EACH_STEP_FOR_MAPPER=$(( ${EACH_STEP} - 1 ))

			case ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} in

				bwa-sw)
					echo BWASW_REF_DB=${REF_DB_TABLE_BWASW[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa-paired)
					echo BWA_REF_DB=${REF_DB_TABLE_BWA[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa)
					echo BWA_REF_DB=${REF_DB_TABLE_BWA[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa-mem)
					echo BWAMEM_REF_DB=${REF_DB_TABLE_BWAMEM[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				bwa-mem-paired)
					echo BWAMEM_REF_DB=${REF_DB_TABLE_BWAMEM[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				bowtie2)
					echo BOWTIE2_REF_DB=${REF_DB_TABLE_BOWTIE2[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				bowtie2-paired)
					echo BOWTIE2_REF_DB=${REF_DB_TABLE_BOWTIE2[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				tmap)
					echo TMAP_REF_DB=${REF_DB_TABLE_TMAP[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				tmap-paired)
					echo TMAP_REF_DB=${REF_DB_TABLE_TMAP[ ${MAPPING_METAG_STEP} ]} >> ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp
				;;

				*)
					echo "Unrecognized mapper : ${nameOFmappers[${EACH_STEP_FOR_MAPPER}]} => abort"
					exit 1
				;;

			esac

			EACH_STEP=$(( ${EACH_STEP} + 1 ))

		done

		sleep 5

		sed -i "s|\(PAIRED=\)\(.*\)|\10|" ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp

		# SINGLE-END DATA
		if [[ ${PAIRED} -eq 0 ]] ; then
			CMD_BASE="mgx-seq-mapping.sh -c ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp -i ${INPUT_READS_MAPPING} -o ${OUTPUT_MAPPING}"
		else # PAIRED-END DATA
			CMD_BASE="mgx-seq-mapping.sh -c ${OUTPUT}/${CONF_NAME}.${MAPPING_METAG_STEP}.tmp -i ${INPUT_READS_MAPPING} -I ${INPUT_READS_PAIR2_MAPPING} -o ${OUTPUT_MAPPING}"
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

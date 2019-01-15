#!/bin/bash

#=======================================================================================================
#
# GET THE PROGRAMM ARGUMENTS
#
#=======================================================================================================
PAIRED=0
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
source bash_functions.lib


# Define input reads
READS_BASENAME=$(basename ${INPUT_READS%.fastq}) ## without the extention

#=======================================================================================================
#
# MERGE BAM FILES IF NECESSARY
#
#=======================================================================================================
METAG_TIME=${SECONDS}

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

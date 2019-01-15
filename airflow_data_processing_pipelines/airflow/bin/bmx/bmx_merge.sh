#!/bin/bash
source bash_functions.lib

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

#=======================================================================================================
#
# LOAD CONFIGURATION FILE
#
#=======================================================================================================

source ${CONF}
READS_BASENAME=$(basename ${INPUT_READS%.fastq}) ## without the extention
READS_BASENAME_PAIR2=$( basename ${INPUT_READS_PAIR2%.fastq} )

INPUT_READS=${OUTPUT}/Preprocessing/${READS_BASENAME}.filtered.fastq
INPUT_READS_PAIR2=${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2}.filtered.fastq

METAG_TIME=${SECONDS}

if [[ ${DO_MERGE_READS} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###############################\n###     Merging : [RUN]     ###\n###############################\n" ; fi

	if [[ ${PAIRED} -eq 1 ]] ; then

		mkdir ${OUTPUT}/Reads_merging/


		CMD_BASE="flash ${INPUT_READS} ${INPUT_READS_PAIR2} -r 300 -f 465 -s 47 -o reads -d ${OUTPUT}/Reads_merging/ -t ${THREADS}"

		if [[ ${SGE_METAG} -eq 0 ]] ; then

			if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "> Commande : ${CMD_BASE}\n" ; fi
			echo ${CMD_BASE} >> ${OUTPUT}/mgx-seq16S-metagenomics.reads_merging.log
			eval ${CMD_BASE} >> ${OUTPUT}/mgx-seq16S-metagenomics.reads_merging.log 2>&1
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

		mkdir ${OUTPUT}/FastQC/
		fastqc ${INPUT_READS} -o ${OUTPUT}/FastQC >> ${OUTPUT}/FastQC/mgx-seq16S-metagenomics.fastqc.log 2>&1


		PAIRED=0
	fi

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n################################\n###     Merging : [DONE]     ###\n################################\n" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#########################################\n###     Merging steps are omitted     ###\n#########################################\n" ; fi

fi

echo -e "> Filtering & QC : $( gettime ${METAG_TIME} ) (minutes:secondes)"
echo -e "> Filtering & QC : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

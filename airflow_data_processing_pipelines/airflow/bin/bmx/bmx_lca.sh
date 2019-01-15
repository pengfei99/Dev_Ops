#!/bin/bash

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
source bash_functions.lib
PAIRED=0

# Define input reads
READS_BASENAME=$(basename ${INPUT_READS%.fastq}) ## without the extention
READS_BASENAME_PAIR2=$( basename ${INPUT_READS_PAIR2%.fastq} )

#=======================================================================================================
#
# LCA
#
#=======================================================================================================
METAG_TIME=${SECONDS}

if [[ ${DO_LCA} -eq 1 ]] ; then

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###########################\n###     LCA : [RUN]     ###\n###########################\n" ; fi

	## Creating the input map file
	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo "### Creating the input map file ... " ; fi
	NB_INPUT_MAP=${#INPUT_MAP_TABLE[@]}
	cat ${INPUT_MAP_TABLE[@]} > ${OUTPUT}/inputMap.txt
	# cat ${INPUT_MAP_16S} > ${OUTPUT}/inputMap.txt
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
	echo "COUNT_MAPPED_READ="${COUNT_MAPPED_READ} >>  ${OUTPUT}/Mapped_reads.txt
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

	echo -e "> LCA : $( gettime ${METAG_TIME} ) (minutes:secondes)"
	echo -e "> LCA : $( gettime ${METAG_TIME} ) (minutes:secondes)" >> ${OUTPUT}/time.txt

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###########################\n###     LCA : [DONE]     ###\n###########################\n" ; fi

else

	if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n###################################\n###     LCA step is omitted     ###\n###################################\n" ; fi

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
			CLEAN_FASTQ_QC=${OUTPUT}/Preprocessing/${READS_BASENAME}.filtered.fastq
			rm ${CLEAN_FASTQ_QC}
		else # PAIRED-END DATA
			CLEAN_FASTQ_QC_PAIR1=${OUTPUT}/Preprocessing/${READS_BASENAME}.filtered.fastq
			CLEAN_FASTQ_QC_PAIR2=${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2}.filtered.fastq
			rm ${CLEAN_FASTQ_QC_PAIR1}
			rm ${CLEAN_FASTQ_QC_PAIR2}
			if [[ -e ${CLEAN_FASTQ_QC_SGL} ]] ; then rm ${CLEAN_FASTQ_QC_SGL} ; fi
		fi

	fi

fi

#=======================================================================================================
#
# SUMMARY
#
#=======================================================================================================

TOTAL_READ_COUNT=$( fqsize ${INPUT_READS} )

if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n#######################\n###     Summary     ###\n#######################\n" ; fi

echo -e "> Number of reads in fastq : ${TOTAL_READ_COUNT}"
echo -e "> Number of reads in fastq : ${TOTAL_READ_COUNT}" >> ${OUTPUT}/summary.txt

# FILTERING QC YES
if [[ ${DO_FILTERING_QC} -eq 1 ]] ; then
	COUNT_READ_AFTER_QC1=$(fqsize ${OUTPUT}/Preprocessing/${READS_BASENAME}.filtered.fastq)
	COUNT_READ_AFTER_QC2=$(fqsize ${OUTPUT}/Preprocessing/${READS_BASENAME_PAIR2}.filtered.fastq)
	echo -e "> Number of reads after QC filtering for Reads 1: ${COUNT_READ_AFTER_QC1}">> ${OUTPUT}/summary.txt
	echo -e "> Number of reads after QC filtering for Reads 2: ${COUNT_READ_AFTER_QC2}">> ${OUTPUT}/summary.txt

	COUNT_READ_AFTER_QC=$((${COUNT_READ_AFTER_QC1}+${COUNT_READ_AFTER_QC2}))
	echo -e "> Number of reads after QC filtering (discarded Reads1 and 2): ${COUNT_READ_AFTER_QC} ($(( ${TOTAL_READ_COUNT} - ${COUNT_READ_AFTER_QC} )) reads discarded)"
	echo -e "> Number of reads after QC filtering (discarded Reads1 and 2): ${COUNT_READ_AFTER_QC} ($(( ${TOTAL_READ_COUNT} - ${COUNT_READ_AFTER_QC} )) reads discarded)" >> ${OUTPUT}/summary.txt

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

mkdir -p ${OUTPUT}/Analyse
echo -e "${OUTPUT}\t${READS_BASENAME}" > ${OUTPUT}/Analyse/bmx_analyses_label.txt

if [[ ${VERBOSE_METAG} -eq 1 ]] ; then echo -e "\n[ THE END ]\n" ; fi


#! /bin/bash

echo -e "\nBEGIN UNMAPPED\n"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================

UNMAPPED_TIME=${SECONDS}

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
	#OLD- retrieves the reads that did not map. For paired-end reads, the script retrieve the reads from the pairs where 0 or 1 reads of the pair did not map.
Depending on the option, the script outputs names of the mapped and unmapped reads, and/or fastq file for unmapped reads. #OLD
	-This script lists mapped reads and unmapped ones. For paired reads it lists proper-mapped read, sgl-mapped reads and unmapped reads. A fastq can also be asked (-f)

DOC:
	A BioTechno documentation of this script is available: http://biopedia.biomerieux.net/biopedia/biotechno/index.php/unmapped.sh
	It contains more details than this usage message.

INPUTS:
	-i		Path to input reads file (fastq format) (mandatory)
	-s		Path to the sam/bam file (mandatory)
	-I		Path to input pair2 reads file (fastq format) (optional)
	-p		Paired reads (1) unpaired (0 - default)
	-f 		Fastq output (1) otherwise (0)
	-r		Reads identifiers mapped and unmapped (1) otherwise (0 - default)
	-o 		output directory
	-d		in the same output, the read names of the pairs are identical (ie. the sam use the reads basename) (0 - default) otherwise (1)
	-S 		Separator for read pairs, default is "/" for Illumina paired-end reads.	

	
OUTPUTS:
If Single-End data:
	- Mapped.txt
	- Unmapped.txt
If Paired-End data:
	- ProperMapped_pair1.txt 
	- ProperMapped_pair2.txt 
	- Mapped_sgl.txt 
	- Unmapped_sgl.txt
	- Unmapped_reads_pair1.txt
	- Unmapped_reads_pair2.txt

One fastq per text file if wanted
	
DEPENDENCIES:
	MIXGENOMIX=/anais/IT/reference/users/maud/ProjetsEclipse/mixgenomix
	SEQUENCING_TOOLS=/Projet/PRG0023-Technology_Research_Program/B1848-Microbial_Sequencing/Tools
	SEQUENCING_TOOLS_SRC=${SEQUENCING_TOOLS}/src
	PATH=$PATH:${MIXGENOMIX}/library/shell
	PATH=$PATH:${SEQUENCING_TOOLS_SRC}/samtools-0.1.18/
	export PATH

EOF
}

#=======================================================================================================
#
# BY DEFAULT VALUES
#
#=======================================================================================================
							
PAIRED=0							
READS_ID=0
FASTQ_OUT=1
DIFFERENT_NAME_FOR_PAIRS_IN_SAM=0
PAIR_SEPARATOR="/"
BWASW=0
GZ_OUTPUT=0
SPACE_IN_NAME=0
APPEND_SUFFIX_1=""
APPEND_SUFFIX_2=""

#=======================================================================================================
#
# Get the program arguments
#
#=======================================================================================================

while getopts "i:s:I:o:p:r:f:g:d:S:b:n:" PARAMETERS
do
	case ${PARAMETERS} in 
		
		# Path to the input reads file
		i) INPUT_READS=${OPTARG};;
		
		# Path to the sam/bam file
		s) SAM_FILE=${OPTARG};;
		
		# Path to the second pairs of reads file
		I) INPUT_READS_PAIR2=${OPTARG};;
		
		# Path to the output directory
		o) OUTPUT=${OPTARG};;
		
		# Paired reads (1) otherwise (0)
		p) PAIRED=${OPTARG};;
		
		# Output reads identifiers (1) otherwise (0)
		r) READS_ID=${OPTARG};;
		
		# Output fastq (1) otherwise (0)
		f) FASTQ_OUT=${OPTARG};;
		
		# Gzip output files (Fastq and txt files)
		g) GZ_OUTPUT=${OPTARG};;
		
		# different names for reads of the same pair in the sam output (1) otherwise (0 - default)
		d) DIFFERENT_NAME_FOR_PAIRS_IN_SAM=${OPTARG};;
		
		# separator for pairs od reads (default /)
		S) PAIR_SEPARATOR=${OPTARG};;
		
		# bam or sam file is obtained with bwa-sw (only the mapped reads are found in the bam/sam file)
		b) BWASW=${OPTARG};;
		
		# if there spaces in read names (eg. for myseq paired reads)
		n) SPACE_IN_NAME=${OPTARG};;

		:) echo " Option -${OPTARG} expects an argument " ; exit ;;

		\?) echo " Unvalid option ${OPTARG} " ; exit ;;

	esac
done

#=======================================================================================================
#
# USAGE RESTRICTIONS TESTS
#
#=======================================================================================================

if [[ ${PAIRED} -eq 1 && -z ${INPUT_READS_PAIR2} ]] ; then
	
	echo "you should provide the path to the file of the second pairs of reads"
	exit 1

fi

if [[ "${PAIR_SEPARATOR}" == ' ' && ${SPACE_IN_NAME} -eq 0 ]] ; then
	
	echo "You have a discrepancy between -S and -n options, I am modifying the -n option to 1 for you"
	SPACE_IN_NAME=1

fi

## Trimming path and file name
EXTENSION="fastq"
READS_FILENAME=$( getFilename ${INPUT_READS} )
READS_BASENAME=$( getBasenameExt ${INPUT_READS} ${EXTENSION} )
READS_DIRNAME=$( getDirname ${INPUT_READS} )

if [ ${PAIRED} -eq 1 ] ; then
	
	READS_FILENAME_PAIR2=$( getFilename ${INPUT_READS_PAIR2} )
	READS_BASENAME_PAIR2=$( getBasenameExt ${INPUT_READS_PAIR2} ${EXTENSION} )

fi

## Bam or sam file
SAM_EXTENSION=$( getExtensionShort ${SAM_FILE} )
SAM_FILENAME=$( getFilename ${SAM_FILE} )
SAM_BASENAME=$( getBasenameExt ${SAM_FILE} ${SAM_EXTENSION} )

#=======================================================================================================
#
# SINGLE-END READS
#
#=======================================================================================================

if [[ ${PAIRED} -eq 0 ]] ; then

	echo -e "\n!!! ATTENTION !!! Le script ne fonctionne pas pour des données single-end contenant '/' comme séparateur de paires (comme des singletons par exemple) !!!\n"

	## getting the mapped reads
	if [[ "${SAM_EXTENSION}" == "sam" ]] ; then

			# echo "HERE sam mapped"
			
			samtools view -F 260 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped.txt

	else

			# echo "HERE not sam mapped"
			# echo "ext : ${SAM_EXTENSION}"
			
			samtools view -F 260 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped.txt

	fi

	# echo "bwa-sw : ${BWASW}"
	
	## getting the unmapped reads
	if [[ ${BWASW} -eq 0 ]] ; then
		
		if [[ "${SAM_EXTENSION}" == "sam" ]] ; then

			# echo "HERE sam unmapped"
			
			samtools view -f 4 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped.txt

		else

			# echo "HERE not sam unmapped"

			samtools view -f 4 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped.txt

		fi

	else
		
		mgx-seq-fqdesc --summary -i ${INPUT_READS} | sed '/landmark size ambiguous quality/d' | cut -f 1 -d ' ' | sort >${OUTPUT}/${SAM_BASENAME}_input.txt
		
		# retrieving names of the reads that did not map
		cat ${OUTPUT}/${SAM_BASENAME}_input.txt ${OUTPUT}/${SAM_BASENAME}_mapped.txt | sort | uniq -u > ${OUTPUT}/${SAM_BASENAME}_unmapped.txt
		
		rm -Rf ${OUTPUT}/${SAM_BASENAME}_input.txt

	fi
	
	## getting corresponding unmapped reads
	if [[ ${FASTQ_OUT} -eq 1 ]] ; then

		# echo "HERE FASTQ_OUT"
	
		if [[ ${SPACE_IN_NAME} -eq 1 ]] ; then

			# echo "HERE space"
			
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.fastq --space-in-name
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_mapped.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.fastq --space-in-name
	
		else
			
			# echo "HERE no space"

			# mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped.txt
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.fastq
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_mapped.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.fastq
	
		fi
		
		if [[ ${GZ_OUTPUT} -eq 1 ]]; then
			
			gzip -f ${OUTPUT}/${SAM_BASENAME}.fastq

		fi
	fi
	
	# cleaning if reads names not wanted
	if [[ ${READS_ID} -eq 0 ]] ; then

		rm ${OUTPUT}/${SAM_BASENAME}_unmapped.txt
		rm ${OUTPUT}/${SAM_BASENAME}_mapped.txt

	else
		
		if [[ ${READS_ID} -eq 1 && ${GZ_OUTPUT} -eq 1 ]]; then
	
			gzip -f ${OUTPUT}/${SAM_BASENAME}_unmapped.txt
			gzip -f ${OUTPUT}/${SAM_BASENAME}_mapped.txt
		
		fi
	fi

#=======================================================================================================
#
# PAIRED-END READS
#
#=======================================================================================================

else
	# Ungzip Fastq files if needed, if not needed nothing is done
	GZ_BOOL=0
	TMP_DIR=${OUTPUT}/tmp_ungzip
	UNGZ_FWD=${TMP_DIR}/reads_fwd.fastq
	ungz ${INPUT_READS} ${UNGZ_FWD}
	
	UNGZ_BWD=${TMP_DIR}/reads_bwd.fastq
	ungz ${INPUT_READS_PAIR2} ${UNGZ_BWD}
	
	# If the Fastq files were ungzipped, use the ungzipped files for the following of the script
	if [[ -e ${UNGZ_FWD} ]]; then
		INPUT_READS=${UNGZ_FWD}
		GZ_BOOL=1
	fi
	if [[ -e ${UNGZ_BWD} ]]; then
		INPUT_READS_PAIR2=${UNGZ_BWD}
		GZ_BOOL=1
	fi
	

	if [[ "${SAM_EXTENSION}" == "sam" ]] ; then
		
		# Paired Mapped 1 => flag 140=4(not unmapped=mapped)+8(not mate unmmaped =mate mapped)+128(not pair2) & 64 (pair1)
		samtools view -F 140 -f 64 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_pair1_tmp.txt
		
		# Paired Mapped Pair 2 => flag 76=4(not unmapped=mapped)+8(not mate unmmaped =mate mapped) +64(not pair1) & 128 (pair2)
		samtools view -F 76 -f 128 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_pair2_tmp.txt
		
		# Mapped sgl => flag 132=4(not unmapped=mapped) +128(not pair2) & 72=8(mate unmmaped)+64(pair1)
		samtools view -F 132 -f 72 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1_tmp.txt
		
		# Mapped sgl => flag 68=4(not unmapped=mapped) +64(not pair1) & 136=8(mate unmmaped)+128(pair2)
		samtools view -F 68 -f 136 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2_tmp.txt

	else
		
		# Mapped Pair 1 => flag 140=4(not unmapped=mapped)+8(not mate unmmaped =mate mapped)+128(not pair2) & 64 (pair1)
		samtools view -F 140 -f 64 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_pair1_tmp.txt
		
		# Mapped Pair 2 => flag 76=4(not unmapped=mapped)+8(not mate unmmaped =mate mapped) +64(not pair1) & 128 (pair2)
		samtools view -F 76 -f 128 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_pair2_tmp.txt
		
		# Mapped sgl => flag 132=4(not unmapped=mapped)+128(not pair2) & 72=8(mate unmmaped)+64(pair1)
		samtools view -F 132 -f 72 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1_tmp.txt
		
		# Mapped sgl => flag 68=4(not unmapped=mapped) +64(not pair1) & 136=8(mate unmmaped)+128(pair2)
		samtools view -F 68 -f 136 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2_tmp.txt
	fi

	if [ "${SAM_EXTENSION}" == "sam" ] ; then
		
		# UnMapped Pair 1 => flag 128(not pair2) 76=4(unmapped)+8(mate unmapped)+64(pair1)
		samtools view -F 128 -f 76 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1_tmp.txt
		
		# UnMapped Pair 2 => flag 64(not pair1) & 140=4(unmapped)+8(mate unmapped)+128(pair2)
		samtools view -F 64 -f 140 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2_tmp.txt
		
		# Mapped sgl => flag 136=8(mate not unmapped=mate mapped)+128(not pair2) & 68=4(unmmaped)+64(pair1)
		samtools view -F 136 -f 68 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1_tmp.txt
		
		# Mapped sgl => flag 8(mate not unmapped=mate mapped)+64(not pair1)  & 132=4(unmmaped)+128(pair2)
		samtools view -F 72 -f 132 -S ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2_tmp.txt
					
	else
		
		# UnMapped Pair 1 => flag 128(not pair2) 76=4(unmapped)+8(mate unmapped)+64(pair1)
		samtools view -F 128 -f 76 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1_tmp.txt
		
		# UnMapped Pair 2 => flag 64(not pair1) & 140=4(unmapped)+8(mate unmapped)+128(pair2)
		samtools view -F 64 -f 140 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2_tmp.txt
		
		# Mapped sgl => flag 136=8(mate not unmapped=mate mapped)+128(not pair2) & 68=4(unmmaped)+64(pair1)
		samtools view -F 136 -f 68 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1_tmp.txt
		
		# Mapped sgl => flag 8(mate not unmapped=mate mapped)+64(not pair1)  & 132=4(unmmaped)+128(pair2)
		samtools view -F 72 -f 132 ${SAM_FILE} | cut -f 1 | sort | uniq > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2_tmp.txt

	fi

	whichPairsSeparator ${INPUT_READS}
	
	if [[ "${PAIR_SEPARATOR}" == "/" ]] ; then
		
		#SEP_PROTECTED="\${PAIR_SEPARATOR}"
		SEP_PROTECTED="\/"
		APPEND_SUFFIX_1=$( head ${INPUT_READS} -n 1 | cut -d ${PAIR_SEPARATOR} -f 2 )
		APPEND_SUFFIX_2=$( head ${INPUT_READS_PAIR2} -n 1 | cut -d ${PAIR_SEPARATOR} -f 2 )

	else

		if [[ ${PAIR_SEPARATOR} == '" "' ]] ; then

			SPACE_IN_NAME=1
			SEP_PROTECTED=" "
			APPEND_SUFFIX_1=$( head ${INPUT_READS} -n 1 | cut -d ' ' -f 2 )
			APPEND_SUFFIX_2=$( head ${INPUT_READS_PAIR2} -n 1 | cut -d ' ' -f 2 )

		else

			echo "unknown separator"
			exit 1

		fi
	fi
	
	# Add Pair Name 
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_1}/g" ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1.txt
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_2}/g" ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2.txt
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_1}/g" ${OUTPUT}/${SAM_BASENAME}_mapped_pair1_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_mapped_pair1.txt
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_2}/g" ${OUTPUT}/${SAM_BASENAME}_mapped_pair2_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_mapped_pair2.txt
	
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_1}/g" ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1.txt
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_2}/g" ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2.txt
	
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_1}/g" ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1.txt
	sed "s/$/${SEP_PROTECTED}${APPEND_SUFFIX_2}/g" ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2_tmp.txt > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2.txt
	
	rm ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1_tmp.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2_tmp.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1_tmp.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2_tmp.txt
	rm ${OUTPUT}/${SAM_BASENAME}_mapped_pair1_tmp.txt ${OUTPUT}/${SAM_BASENAME}_mapped_pair2_tmp.txt ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1_tmp.txt ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2_tmp.txt 
	
	cat ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2.txt > ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl.txt
	cat ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1.txt ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2.txt > ${OUTPUT}/${SAM_BASENAME}_mapped_sgl.txt
	rm ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2.txt 
	rm ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1.txt ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2.txt 
	
	## getting corresponding unmmaped reads
	if [[ ${FASTQ_OUT} -eq 1 ]] ; then

		if [[ ${SPACE_IN_NAME} -eq 0 ]] ; then

			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.pair1.fastq
			mgx-seq-fqget -i ${INPUT_READS_PAIR2} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.pair2.fastq
			
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_mapped_pair1.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.pair1.fastq
			mgx-seq-fqget -i ${INPUT_READS_PAIR2} -r ${OUTPUT}/${SAM_BASENAME}_mapped_pair2.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.pair2.fastq
			
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_mapped_sgl.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.sgl.fastq
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.sgl.fastq
			
		else

			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.pair1.fastq --space-in-name
			mgx-seq-fqget -i ${INPUT_READS_PAIR2} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.pair2.fastq --space-in-name
			
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_mapped_pair1.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.pair1.fastq --space-in-name
			mgx-seq-fqget -i ${INPUT_READS_PAIR2} -r ${OUTPUT}/${SAM_BASENAME}_mapped_pair2.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.pair2.fastq --space-in-name
			
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_1.txt > ${OUTPUT}/${SAM_BASENAME}.mapped.sgl.fastq --space-in-name
			mgx-seq-fqget -i ${INPUT_READS_PAIR2} -r ${OUTPUT}/${SAM_BASENAME}_mapped_sgl_2.txt >> ${OUTPUT}/${SAM_BASENAME}.mapped.sgl.fastq --space-in-name
			
			mgx-seq-fqget -i ${INPUT_READS} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_1.txt > ${OUTPUT}/${SAM_BASENAME}.unmapped.sgl.fastq --space-in-name
			mgx-seq-fqget -i ${INPUT_READS_PAIR2} -r ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl_2.txt >> ${OUTPUT}/${SAM_BASENAME}.unmapped.sgl.fastq --space-in-name
			
		fi
		
		if [[ ${GZ_OUTPUT} -eq 1 ]]; then

			gzip -f ${OUTPUT}/${SAM_BASENAME}.mapped.pair1.fastq
			gzip -f ${OUTPUT}/${SAM_BASENAME}.mapped.pair2.fastq
			gzip -f ${OUTPUT}/${SAM_BASENAME}.unmapped.pair1.fastq
			gzip -f ${OUTPUT}/${SAM_BASENAME}.unmapped.pair2.fastq
			gzip -f ${OUTPUT}/${SAM_BASENAME}.mapped.sgl.fastq
			gzip -f ${OUTPUT}/${SAM_BASENAME}.mapped.sgl.fastq

		fi
	fi

	## cleaning if reads names not wanted
	if [ ${READS_ID} -eq 0 ] ; then

		rm ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1.txt ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2.txt
		rm ${OUTPUT}/${SAM_BASENAME}_mapped_sgl.txt ${OUTPUT}/${SAM_BASENAME}_mapped_pair1.txt ${OUTPUT}/${SAM_BASENAME}_mapped_pair2.txt

	else
		
		if [[ ${READS_ID} -eq 1 && ${GZ_OUTPUT} -eq 1 ]]; then
			
			gzip -f ${OUTPUT}/${SAM_BASENAME}_unmapped_sgl.txt
			gzip -f ${OUTPUT}/${SAM_BASENAME}_unmapped_pair1.txt
			gzip -f ${OUTPUT}/${SAM_BASENAME}_unmapped_pair2.txt
			gzip -f ${OUTPUT}/${SAM_BASENAME}_mapped_sgl.txt
			gzip -f ${OUTPUT}/${SAM_BASENAME}_mapped_pair1.txt
			gzip -f ${OUTPUT}/${SAM_BASENAME}_mapped_pair2.txt

		fi
	fi
	
	# Remove tmp directory if needed
	if [[ ${GZ_BOOL} -eq 1 ]]; then
		rm -Rf ${OUTPUT}/tmp_ungzip
	fi
fi

#=======================================================================================================
#
# STOPING TIMER
#
#=======================================================================================================

echo -e "\nTotal running time for unmapped.sh : $( gettime ${UNMAPPED_TIME} ) (minutes:secondes)"

echo -e "\nEND UNMAPPED\n"

exit 0
#!/bin/bash
# fqPreproc : a BASH script to filter reads from FASTQ formatted files
# Copyright (C) 2011 Ghislaine Guigon & 2015 Thibaut Montagne

echo -e "\nBEGIN FQPREPROC\n"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================

FQPREPROC_TIME=${SECONDS}

#=======================================================================================================
#
# LOAD BASH FUNCTIONS
#
#=======================================================================================================

source bash_functions.lib

#=======================================================================================================
#
# INSTALATION
#
#=======================================================================================================

# Prior to any launch, first verify that the following pathes to each required binary are correct:

# FastqToSanger : to convert any fastq-formatted file into sanger-encoded file
# In your path : mgx-fq2sanger.pl

# sickle : to perform read trimming (https://github.com/najoshi/sickle)
# In your path : sickle

# fastq_quality_filter : to filter out non-confident reads (part of the FASTX-Toolkit : hannonlab.cshl.edu/fastx_toolkit/)
# In your path : fastq_quality_filter
# Or in /Projet/PRG0023-Technology_Research_Program/B1848-Microbial_Sequencing/Tools/src/fastx_toolkit-0.0.13_chris/bin/bin/fastq_quality_filter

# fastx_artifacts_filter : to filter out artifactual reads (part of the FASTX-Toolkit : hannonlab.cshl.edu/fastx_toolkit/)
# In your path : fastx_artifacts_filter
# Or in /Projet/PRG0023-Technology_Research_Program/B1848-Microbial_Sequencing/Tools/src/fastx_toolkit-0.0.13_chris/bin/bin/fastx_artifacts_filter

# fqextract : to extract specified reads from a fastq formatted file (https://gist.github.com/1168330/)
# In your path : fqextract
# Or in : /Projet/PRG0023-Technology_Research_Program/B1848-Microbial_Sequencing/Tools/src/fqtools-1.0/src/fqextract

# fqduplicate : to obtain the read names that are present several times within a FASTQ formated file
# In your path : fqduplicate
# Or in /Projet/PRG0023-Technology_Research_Program/B1848-Microbial_Sequencing/Tools/src/fqtools-1.0/src/fqduplicate.pl

# Secondly, give the execute permission on the script fqPreproc.sh by using the following command: chmod +x fqPreproc.sh

#=======================================================================================================
#
# USAGE
#
#=======================================================================================================

if [ "${1}" = "-?" ] || [ $# -le 1 ] ; then

cat << EOF

fqPreproc : Filtering reads from FASTQ files

USAGE :

	fqPreproc.sh [OPTIONS]

f:r:q:l:m:p:t:s:x:y:z:n:k:e:c

OPTIONS :

	-f <infile> : FASTQ formatted input file name (mandatory option)
	-r <infile> : when using paired-ends data, this option allows inputing the second file (i.e. reverse reads)
	-q <int>    : quality score threshold (default: 20); all bases with quality score below this threshold are considered as non-confident
	-l <int>    : minimum required length for a read (default: half read length)
	-m <int>    : maximum required length for a read, trim right part of reads which length is higher than the provided value
	-p <int>    : minimum percent of bases (default: 80) that must have a quality score higher than the fixed threshold (set by option -q)
	-t <int>    : the number of bases to trim in 5\' extremity, must be a positive integer
	-s <string> : a sequence of tasks to iteratively perform, each being set by one of the following uppercase letter (by default, the following task sequence is used : TCFCA) :
		A : each artefactual read is filtered out
		C : the number of (remaining) reads is displayed
		D : all duplicated reads are removed
		F : each read containing too few confident bases is filtered out (the minimum percentage of confident bases is set with option -p)
		L : trimming reads in 5\" extremity and/or to a fixed length
		M : miseq preprocess (quality filtering, trimming, adapters decontamination, substitution error correction)
		T : each read is trimmed to remove non-confident bases at the 5\' and 3\' (quality score threshold is set with option -q) and all short reads are filtered out (minimum read length is set with option -l)
		V : miseq preprocess (quality filtering, trimming, adapters decontamination)
	-x <file>   : single-end : output file name ; paired-ends : forward read output file name (default: <option -f>.<option -s>.fastq )
	-y <file>   : paired-ends data only : reverse read output file name (default: <option -r>.<option -s>.fastq)
	-z <file>   : paired-ends data only : single read output file name (default: <option -f>.<option -s>.sgl.fastq)
	-n <int>    : number of threads (for miseq only)
	-k <int>    : the length of the kmer to use in SGA correct (optional, 31 by default, usefull when step M is performed)
	-e <int>    : minimun kmer occurence for SGA correct, attempt to correct kmers that are seen less than <int> times (optional, 3 by default, usefull when step M is performed)
	-c <int>    : if -c is 1, index and log files from MiSeq step (M) are cleaned, if -c is 0 cleaning files not performed

EXAMPLES :

	- Single-ends reads inside a file named 'reads.fastq', default options, and output file named 'reads.clean.fastq' :
		fqPreproc.sh -f reads.fastq -x reads.clean.fastq
	This will return the FASTQ formatted file 'reads.DTFAD.fastq' (Sanger encoding)

	- Paired-ends reads inside files named 'fwd.fastq' and 'rev.fastq', minimum read length of 30 bps, quality score threshold of 25 :
		fqPreproc.sh -f fwd.fastq -r rev.fastq -l 30 -q 25
	This will return the two FASTQ formatted files 'fwd.DTFAD.fastq' and 'rev.DTFAD.fastq', as well as single reads inside 'fwd.DTFAD.sgl.fastq' (Sanger encoding)

EOF

exit

fi

#################################################################################
# Functions
#################################################################################

# randomfile ${INFILE}
	#INFILE: file name, this will returns the randomly generated file name INFILE.RANDOM
randomfile() {

	RDMF=${1}.${RANDOM}

	while [ -e ${RDMF} ]
	do
		RDMF=${1}.${RANDOM}
	done

	echo ${RDMF}

}

# fq2sanger ${INFILE} $OUTFILE
	# INFILE: input file name in fastq format (with extension .fastq)
	# OUTFILE: output file name converted from INFILE with sanger quality scores
fq2sanger() {

	FQ2SANGER_TMP=$( randomfile ${1} )
	mgx-fq2sanger.pl -i ${1} -o ${2} > ${FQ2SANGER_TMP}
	head -2 ${FQ2SANGER_TMP} >> ${3}
	rm ${FQ2SANGER_TMP}

	if [ ! -e ${2} ] ; then cp ${1} ${2} ; fi

}

# fqtrim_se ${INFILE} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} $OUTFILE
	# INFILE: input file name in fastq and sanger format
	# QUALITY_THRESHOLD: integer between 0 and 40
	# MIN_READ_LENGTH: integer higher than 0
	# OUTFILE: output file name containing trimmed single-end reads
fqtrim_se() {

	sickle se --quiet -f ${1} -t sanger -q ${2} -l ${3} -o ${4}

}

# fqtrim_pe ${INFILE_FWD} ${INFILE_REV} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} $OUTFILE_FWD $OUTFILE_REV $OUTFILE_SGL
	# INFILE_FWD: input file name containing forward reads in fastq and sanger format
	# INFILE_REV: input file name containing reverse reads in fastq and sanger format
	# QUALITY_THRESHOLD: integer between 0 and 40
	# MIN_READ_LENGTH: integer higher than 0
	# OUTFILE_FWD: output file name containing trimmed forward reads
	# OUTFILE_REV: output file name containing trimmed reverse reads
	# OUTFILE_SGL: output file name containing single reads
fqtrim_pe() {

	sickle pe --quiet -f ${1} -r ${2} -t sanger -q ${3} -l ${4} -o ${5} -p ${6} -s ${7}

}

# fqfilter ${INFILE} ${QUALITY_THRESHOLD} ${PERCENT_CONFIDENT_BPS} $OUTFILE
	# INFILE: input file name in fastq and sanger format
	# QUALITY_THRESHOLD: integer between 0 and 40
	# PERCENT_CONFIDENT_BPS: integer between 0 and 100
	# OUTFILE: output file name containing filtered single-end reads
fqfilter() {

	fastq_quality_filter -Q 33 -i ${1} -q ${2} -p ${3} -o ${4}

}

# fqartfilter ${INFILE} $OUTFILE
	# INFILE: input file name in fastq or fasta format
	# OUTFILE: output file name containing single-end reads without artifacts
fqartfilter() {

	fastx_artifacts_filter -Q 33 -i ${1} -o ${2}

}

# fqnoduplicate_se $INFILE $OUTFILE
	# INFILE: input file name in fastq format
	# OUTFILE: output file name containing single-end reads with no duplicate
fqnoduplicate_se() {

	FQNODUPLICATE_SE_TMP=$( randomfile ${1} )
	fqduplicate ${1} > ${FQNODUPLICATE_SE_TMP}
	fqextract -px -l ${FQNODUPLICATE_SE_TMP} ${1} > ${2} ; rm ${FQNODUPLICATE_SE_TMP}

}

# fqnoduplicate_pe $INFILE_FWD $INFILE_REV $OUTFILE_FWD $OUTFILE_REV
	# INFILE_FWD: input file name containing forward reads in fastq and sanger format
	# INFILE_REV: input file name containing reverse reads in fastq and sanger format
	# OUTFILE_FWD: output file name containing forward reads with no paired duplicate
	# OUTFILE_REV: output file name containing reverse reads with no paired duplicate
fqnoduplicate_pe() {

	FQNODUPLICATE_PE_TMP=$( randomfile ${1} )
	fqduplicate ${1} ${2} > ${FQNODUPLICATE_PE_TMP}
	fqextract -px -l ${FQNODUPLICATE_PE_TMP} ${1} > ${3}
	fqextract -px -l ${FQNODUPLICATE_PE_TMP} ${2} > ${4}
	rm ${FQNODUPLICATE_PE_TMP}

}

# fqintersect $INFILE_FWD $INFILE_REV $OUTFILE_FWD $OUTFILE_REV $OUTFILE_SGL [RA]
	# INFILE_FWD: input file name containing forward reads in fastq and sanger format
	# INFILE_REV: input file name containing reverse reads in fastq and sanger format
	# OUTFILE_FWD: output file name containing each forward read for which the reverse read exists
	# OUTFILE_REV: output file name containing each reverse read for which the forward read exists
	# OUTFILE_SGL: output file name containing single reads
	# [RA]: if 'R', then all outfiles are replaced; if 'A', all outfiles are appended
fqintersect() {

	sed -n '1~4p' ${1} > ${1}.tmp ; sed 's/^@//g' ${1}.tmp > ${1}.idf ; rm ${1}.tmp ; grep -o ":.*[/# ]" ${1}.idf > ${1}.id ; sort ${1}.id -o ${1}.ids ; rm ${1}.id
	sed -n '1~4p' ${2} > ${2}.tmp ; sed 's/^@//g' ${2}.tmp > ${2}.idf ; rm ${2}.tmp ; grep -o ":.*[/# ]" ${2}.idf > ${2}.id ; sort ${2}.id -o ${2}.ids ; rm ${2}.id
	comm -2 -3 ${1}.ids ${2}.ids > ${1}.idu ; comm -1 -3 ${1}.ids ${2}.ids > ${2}.idu ; rm ${1}.ids ${2}.ids
	grep -F -f ${1}.idu ${1}.idf > ${1}.idfsgl ; rm ${1}.idu ${1}.idf
	grep -F -f ${2}.idu ${2}.idf > ${2}.idfsgl ; rm ${2}.idu ${2}.idf

	if [ "${6}" = "R" ] ; then if [ -e ${3} ] ; then rm ${3} ; fi ; if [ -e ${4} ] ; then rm ${4} ; fi ; if [ -e ${5} ] ; then rm ${5} ; fi ; fi

	fqextract -px -l ${1}.idfsgl ${1} >> ${3}
	fqextract -px -l ${2}.idfsgl ${2} >> ${4}
	fqextract -p -l ${1}.idfsgl ${1} >> ${5}
	fqextract -p -l ${2}.idfsgl ${2} >> ${5}
	rm ${1}.idfsgl ${2}.idfsgl

}

# getReadIDandSuffix file.fastq
	# IF first line of file.fastq is : @M01453:30:000000000-ACKR4:1:1101:22692:1086 1:N:0:1
	# ID --> @M01453
	# SUFFIX --> 1:N:0:1

	# IF first line of file.fastq is : @READ#0 1

getReadIDandSuffix(){

	FIRST_LINE=$( head -1 ${1} )

	if [[ ${FIRST_LINE} == *"@READ"* ]] ; then
		ID="@READ"
	else
		ID=$( echo ${FIRST_LINE} | cut -d":" -f1 )
	fi

	SUFFIX=$( echo ${FIRST_LINE} | cut -d" " -f2 )

}

# miseq_preproc
	# ${A5MISEQ}/trimmomatic.jar
	# ${A5MISEQ}/adapter.fasta
	# Only paired end
	# miseq_preproc	THREADS	INPUT_READS	OUTPUT_READS	BASE_QUALITY_THRESOLD	MIN_READ_LENGTH	KMER_SIZE	KMER_FREQ	OUTPUT	CLEAN STEPS
	# miseq_preproc	1		2			3				4					 	5			 	6			7			8		9		10
miseq_preproc(){

	AVAILABLE_MEMORY=$( grep MemTotal /proc/meminfo | awk '{print $2}' )
	SGA_INDEX_MEMORY=$( echo "${AVAILABLE_MEMORY} / 4 " | bc )

	BASENAME=$( getBasenameShort ${2} )

	# TRIMMOMATIC
		# ILLUMINACLIP: Cut adapter and other illumina-specific sequences from the read. ILLUMINACLIP:<fastaWithAdaptersEtc>:<seed mismatches>:<palindrome clip threshold>:<simple clip threshold>:<minAdapterLength>:<keepBothReads>
		# fastaWithAdaptersEtc: specifies the path to a fasta file containing all the adapters, PCR sequences etc. The naming of the various sequences within this file determines how they are used.
		# seedMismatches: specifies the maximum mismatch count which will still allow a full match to be performed
		# palindromeClipThreshold: specifies how accurate the match between the two 'adapter ligated' reads must be for PE palindrome read alignment.
		# simpleClipThreshold: specifies how accurate the match between any adapter etc. sequence must be against a read.
		# minAdapterLength: In addition to the alignment score, palindrome mode can verify that a minimum length of adapter has been detected.
			# If unspecified, this defaults to 8 bases, for historical reasons. However, since palindrome mode has a very low false positive rate, thiscan be safely reduced, even down to 1, to allow shorter adapter fragments to be removed.
		# keepBothReads: After read-though has been detected by palindrome mode, and the adapter sequence removed, the reverse read contains the same sequence information as the forward read, albeit in reverse complement.
			# For this reason, the default behaviour is to entirely drop the reverse read. By specifying "true" for this parameter, the reverse read will also be retained, which may be useful e.g. if the downstream tools cannot handle a
			# combination of paired and unpaired reads.
		# SLIDINGWINDOW: Perform a sliding window trimming, cutting once the average quality within the window falls below a threshold. SLIDINGWINDOW:<windowSize>:<requiredQuality>
		# windowSize: specifies the number of bases to average across
		# requiredQuality: specifies the average quality required.
		# LEADING: Cut bases off the start of a read, if below a threshold quality. LEADING:<quality>
		# quality: Specifies the minimum quality required to keep a base.
		# TRAILING: Cut bases off the end of a read, if below a threshold quality. TRAILING:<quality>
		# quality: Specifies the minimum quality required to keep a base.
		# CROP: Cut the read to a specified length. CROP:<length>
		# length: The number of bases to keep, from the start of the read.
		# HEADCROP: Cut the specified number of bases from the start of the read. HEADCROP:<length>
		# length: The number of bases to remove from the start of the read.
		# MINLEN: Drop the read if it is below a specified length. MINLEN:<length>
		# length: Specifies the minimum length of reads to be kept.
		# TOPHRED33: Convert quality scores to Phred-33
		# TOPHRED64: Convert quality scores to Phred-6

	echo -e "\t\t$( gettime ${STIME} ) BEGIN TRIMMOMATIC"
	if [[ ${9} -eq 0 ]] ; then
		if [ ! -d "${OUTPUT}/Trimmomatic_${BASENAME}" ]; then mkdir ${OUTPUT}/Trimmomatic_${BASENAME} ; fi
		java -jar ${A5MISEQ}/trimmomatic.jar SE -threads ${1} -phred33 -trimlog ${OUTPUT}/Trimmomatic_${BASENAME}/trim.log ${2} ${3} ILLUMINACLIP:${A5MISEQ}/adapter.fasta:2:30:10 SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:${5} 1> ${OUTPUT}/Trimmomatic_${BASENAME}/trimmomatic.out 2> ${OUTPUT}/Trimmomatic_${BASENAME}/trimmomatic.err
	else
		java -jar ${A5MISEQ}/trimmomatic.jar SE -threads ${1} -phred33 ${2} ${3} ILLUMINACLIP:${A5MISEQ}/adapter.fasta:2:30:10 SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:${5} &> /dev/null
	fi
	echo -e "\t\t$( gettime ${STIME} ) END TRIMMOMATIC\n"
	rm ${2} # DELETE TRIM.LOG

	# CARD=$( fqsize ${3} )
	# echo -e "\t\t> Number of reads ater trimmomatic : ${CARD}\n"

	# SGA PREPROCESS --> OUTPUT IN ONE FILE
		# -o, --out=FILE		: write the reads to FILE (default: stdout)
		# --phred64		 : the input reads are phred64 scaled. They will be converted to phred33.
		# -q, --quality-trim=INT	: perform Heng Li's BWA quality trim algorithm. Reads are trimmed according to the formula : "argmax_x{\sum_{i=x+1}^l(INT-q_i)} if q_l < INT" where l is the original read length.
		# -f, --quality-filter=INT	: discard the read if it contains more than INT low-quality bases. Bases with phred score <= 3 are considered low quality. Default: no filtering. The filtering is applied after trimming so
		#				 bases removed are not counted.
		# -m, --min-length=INT		: discard sequences that are shorter than INT this is most useful when used in conjunction with --quality-trim. Default: 40
		# -p, --pe-mode=INT		 : 0 - do not treat reads as paired (default)
		# 1 - reads are paired with the first read in READS1 and the second read in READS2. The paired reads will be interleaved in the output file
		# 2 - reads are paired and the records are interleaved within a single file.
		# -h, --hard-clip=INT		 : clip all reads to be length INT. In most cases it is better to use the soft clip (quality-trim) option.
		# --permute-ambiguous		 : Randomly change ambiguous base calls to one of possible bases. For example M will be changed to A or C. If this option is not specified, the entire read will be discarded.
		# -s, --sample=FLOAT		: Randomly sample reads or pairs with acceptance probability FLOAT.
		# --dust			: Perform dust-style filtering of low complexity reads. If you are performing de novo genome assembly, you probably do not want this.
		# --dust-threshold=FLOAT	: filter out reads that have a dust score higher than FLOAT (default: 4.0). This option implies --dust

	# OUTPUT TRIMMOMATIC BECOME INPUT SGA PREPROCESS
	mv ${3} ${2}

	echo -e "\t\t$( gettime ${STIME} ) BEGIN SGA PREPROCESS"

	# sga preprocess --quality-trim=25 --quality-filter=20 --min-length=${5} --pe-mode=0 ${2} > ${3} 2> ${OUTPUT}/SGA_Preprocess_${BASENAME}/sga_preprocess.err

	if [[ ${9} -eq 0 ]] ; then
		if [ ! -d "${OUTPUT}/SGA_Preprocess_${BASENAME}" ]; then mkdir ${OUTPUT}/SGA_Preprocess_${BASENAME} ; fi
		${A5MISEQ}/sga preprocess --quality-trim=25 --quality-filter=20 --min-length=${5} --pe-mode=0 ${2} > ${3} 2> ${OUTPUT}/SGA_Preprocess_${BASENAME}/sga_preprocess.err
	else
		${A5MISEQ}/sga preprocess --quality-trim=25 --quality-filter=20 --min-length=${5} --pe-mode=0 ${2} > ${3} 2> /dev/null
	fi
	echo -e "\t\t$( gettime ${STIME} ) END SGA PREPROCESS\n"


	# SGA INDEX
		# -d, --disk=NUM		: use disk-based BWT construction algorithm. The suffix array/BWT will be constructed for batchs of NUM reads at a time. To construct the suffix array of 200 megabases of sequence requires ~2GB of
		#				 memory, set this parameter accordingly.
		# -t, --threads=NUM	 : use NUM threads to construct the index (default: 1)
		# -c, --check		 : validate that the suffix array/bwt is correct
		# -p, --prefix=PREFIX : write index to file using PREFIX instead of prefix of READSFILE
		# --no-reverse		: suppress construction of the reverse BWT. Use this option when building the index for reads that will be error corrected using the k-mer corrector, which only needs the forward index
		# -g, --gap-array=N	 : use N bits of storage for each element of the gap array. Acceptable values are 4,8,16 or 32. Lower values can substantially reduce the amount of memory required at the cost of less predictable
		#				 memory usage. When this value is set to 32, the memory requirement is essentially deterministic and requires ~5N bytes where N is the size of the FM-index of READS2. The default value is 8.

	if [[ ${10} == *"M"* ]] ; then
		# OUTPUT SGA PREPROCESS BECOME INPUT SGA INDEX
		mv ${3} ${2}
		if [ ! -d "${OUTPUT}/SGA_Index_${BASENAME}" ]; then mkdir ${OUTPUT}/SGA_Index_${BASENAME} ; fi
		echo -e "\t\t$( gettime ${STIME} ) BEGIN SGA INDEX"
		if [[ ${9} -eq 0 ]] ; then
			${A5MISEQ}/sga index --threads=${1} --prefix=${OUTPUT}/SGA_Index_${BASENAME}/index --disk=${SGA_INDEX_MEMORY} --no-reverse ${2} > ${OUTPUT}/SGA_Index_${BASENAME}/index.out 2> ${OUTPUT}/SGA_Index_${BASENAME}/index.err
		else
			${A5MISEQ}/sga index --threads=${1} --prefix=${OUTPUT}/SGA_Index_${BASENAME}/index --disk=${SGA_INDEX_MEMORY} --no-reverse ${2} &> /dev/null
		fi
		echo -e "\t\t$( gettime ${STIME} ) END SGA INDEX\n"

		# SGA CORRECT
			# Correct sequencing errors in all the reads in READSFILE
			# -p, --prefix=PREFIX : use PREFIX for the names of the index files (default: prefix of the input file)
			# -o, --outfile=FILE	: write the corrected reads to FILE (default: READSFILE.ec.fa)
			# -t, --threads=NUM	 : use NUM threads to compute the overlaps (default: 1)
			# --discard		 : detect and discard low-quality reads
			# -d, --sample-rate=N : use occurrence array sample rate of N in the FM-index. Higher values use significantly less memory at the cost of higher runtime. This value must be a power of 2 (default: 128)
			# -a, --algorithm=STR : specify the correction algorithm to use. STR must be one of kmer, hybrid, overlap. (default: kmer)
			# --metrics=FILE		: collect error correction metrics (error rate by position in read, etc) and write them to FILE

			# Kmer correction parameters
			# -k, --kmer-size=N		 : The length of the kmer to use. (default: 31)
			# -x, --kmer-threshold=N	: Attempt to correct kmers that are seen less than N times. (default: 3)
			# -i, --kmer-rounds=N		 : Perform N rounds of k-mer correction, correcting up to N bases (default: 10)
			# --learn			 : Attempt to learn the k-mer correction threshold (experimental). Overrides -x parameter.

			# Overlap correction parameters:
			# -e, --error-rate		: the maximum error rate allowed between two sequences to consider them overlapped (default: 0.04)
			# -m, --min-overlap=LEN	 : minimum overlap required between two reads (default: 45)
			# -c, --conflict=INT		: use INT as the threshold to detect a conflicted base in the multi-overlap (default: 5)
			# -l, --seed-length=LEN	 : force the seed length to be LEN. By default, the seed length in the overlap step is calculated to guarantee all overlaps with --error-rate differences are found. This option removes
			#				 the guarantee but will be (much) faster. As SGA can tolerate some missing edges, this option may be preferable for some data sets.
			# -s, --seed-stride=LEN	 : force the seed stride to be LEN. This parameter will be ignored unless --seed-length is specified (see above). This parameter defaults to the same value as --seed-length
			# -b, --branch-cutoff=N	 : stop the overlap search at N branches. This parameter is used to control the search time for highly-repetitive reads. If the number of branches exceeds N, the search stops and the
			#	read will not be corrected. This is not enabled by default.
			# -r, --rounds=NUM		: iteratively correct reads up to a maximum of NUM rounds (default: 1)
		echo -e "\t\t$( gettime ${STIME} ) BEGIN SGA CORRECT"

		if [[ ${9} -eq 0 ]] ; then
			if [ ! -d "${OUTPUT}/SGA_Correct_${BASENAME}" ] ; then mkdir ${OUTPUT}/SGA_Correct_${BASENAME} ; fi
			${A5MISEQ}/sga correct --threads=${1} --prefix=${OUTPUT}/SGA_Index_${BASENAME}/index --kmer-size=${6} --kmer-threshold=${7} ${2} -o ${3} > ${OUTPUT}/SGA_Correct_${BASENAME}/sga_correct.out 2> ${OUTPUT}/SGA_Correct_${BASENAME}/sga_correct.err
		else
			${A5MISEQ}/sga correct --threads=${1} --prefix=${OUTPUT}/SGA_Index_${BASENAME}/index --kmer-size=${6} --kmer-threshold=${7} ${2} -o ${3} &> /dev/null
		fi
		echo -e "\t\t$( gettime ${STIME} ) END SGA CORRECT\n"
		if [[ ${9} -eq 1 ]] ; then
			rm -r ${OUTPUT}/SGA_Index_${BASENAME}/
		fi
	fi
}

#=======================================================================================================
#
# BY DEFAULT VALUES
#
#=======================================================================================================

FASTQ_FWD="XXX"
FASTQ_REV="XXX"
OUTFASTQ_FWD="XXX"
OUTFASTQ_REV="XXX"
OUTFASTQ_SGL="XXX"
#STEPS="CTCFCAC"
STEPS="CMC"
QUALITY_THRESHOLD=20
MIN_READ_LENGTH=50
PERCENT_CONFIDENT_BPS=80
TRIM_LEFT=0
THREADS=1
KMER_SIZE=31
KMER_FREQ=3
CLEAN=0

#=======================================================================================================
#
# GET THE PROGRAMM ARGUMENTS
#
#=======================================================================================================

while getopts f:r:x:y:z:s:q:l:p:m:t:n:k:e:c: OPTION
do
	case ${OPTION} in
		f)
			FASTQ_FWD="${OPTARG}"
			if [ ! -e ${FASTQ_FWD} ] ; then echo " problem with input file (option -f): '${FASTQ_FWD}' does not exist" ; exit ; fi
			;;
		r)
			FASTQ_REV="${OPTARG}"
			if [ ! -e ${FASTQ_REV} ] ; then echo " problem with input file (option -r): '${FASTQ_REV}' does not exist" ; exit ; fi
			PAIRED_ENDS="true"
			;;
		x)
			OUTFASTQ_FWD="${OPTARG}"
			#if [ -e $OUTFASTQ_FWD ]
			#then echo " [WARNING] the specified output file $OUTFASTQ_FWD exists and will be removed"; rm -i $OUTFASTQ_FWD ; if [ -e $OUTFASTQ_FWD ]; then exit; fi
			#fi
			;;
		y)
			OUTFASTQ_REV="${OPTARG}"
			#if [ -e $OUTFASTQ_REV ]
			#then echo " [WARNING] the specified output file $OUTFASTQ_REV exists and will be removed"; rm -i $OUTFASTQ_REV ; if [ -e $OUTFASTQ_REV ]; then exit; fi
			#fi
			;;
		z)
			OUTFASTQ_SGL="${OPTARG}"
			#if [ -e $OUTFASTQ_SGL ]
			#then echo " [WARNING] the specified output file $OUTFASTQ_SGL exists and will be removed"; rm -i $OUTFASTQ_SGL ; if [ -e $OUTFASTQ_SGL ]; then exit; fi
			#fi
			;;
		s)
			STEPS="${OPTARG}"
			;;
		q)
			QUALITY_THRESHOLD=${OPTARG}
			if [ ${QUALITY_THRESHOLD} -lt 0 ] || [ ${QUALITY_THRESHOLD} -gt 40 ] ; then echo " the quality score threshold must range from 0 to 40 (option -q)" ; exit ; fi
			;;
		l)
			MIN_READ_LENGTH=${OPTARG}
			if [ ${MIN_READ_LENGTH} -lt 0 ] ; then echo " the read length threshold must be a positive integer (option -l)" ; exit ; fi

			;;
		p)
			PERCENT_CONFIDENT_BPS=${OPTARG}
			if [ ${PERCENT_CONFIDENT_BPS} -lt 0 ] || [ ${PERCENT_CONFIDENT_BPS} -gt 100 ] ; then echo " the minimum percent of confident bases must range from 0 to 100 (option -p)" ; exit ; fi

			;;
		m)
			MAX_READ_LENGTH=${OPTARG}
			if [ ${MAX_READ_LENGTH} -lt 0 ] ; then echo " the max read length threshold must be a positive integer (option -m)" ; exit ; fi

			;;
		t)
			TRIM_LEFT=${OPTARG}
			if [ ${TRIM_LEFT} -lt 0 ] ; then echo " the number of bases to trim in 5' extremity must be a positive integer (option -t)" ; exit ; fi

			;;
		n)
			THREADS=${OPTARG}

			;;
		k)
			KMER_SIZE=${OPTARG}

			;;
		e)
			KMER_FREQ=${OPTARG}
			;;
		c)
			CLEAN=${OPTARG}
			;;
	esac
done

#=======================================================================================================
#
# USAGE RESTRICTIONS TESTS
#
#=======================================================================================================

if [ "${FASTQ_FWD}" = "XXX" ] ; then echo -e " no FASTQ formatted input file (mandatory option -f)" ; exit ; fi
if [[ ${STEPS} == *"M"* ]] ; then
	if [[ ${CLEAN} -ne 0 && ${CLEAN} -ne 1 ]] ; then echo -e "Variable CLEAN must be 0 or 1 for cleaning index and log files (Trimmomatic, SGA)" ; exit 1 ; fi
fi

#=======================================================================================================
#
# READING FASTQ FILTERING STEPS TO PERFORM
#
#=======================================================================================================

OUT=""
STEP_NB=${#STEPS}
STEP_ID=0

while [ ${STEP_ID} -lt ${STEP_NB} ]
do
	STEP=${STEPS:$STEP_ID:1}

	if [ "${STEP}" = "A" ] || [ "${STEP}" = "D" ] || [ "${STEP}" = "F" ] || [ "${STEP}" = "L" ] || [ "${STEP}" = "M" ] || [ "${STEP}" = "T" ] ; then OUT="${OUT}${STEP}" ; fi

	STEP_ID=$(( ${STEP_ID} + 1 ))

done

if [[ "${STEPS}" =~ ^C*$ ]] ; then OUT="C" ; fi

#=======================================================================================================
#
# COMPUTING READ LENGTHS
#
#=======================================================================================================

SEQ=$( head -2 ${FASTQ_FWD} | tail -1 )
READ_LENGTH=${#SEQ}
if [ ${MIN_READ_LENGTH} -eq 0 ] ; then MIN_READ_LENGTH=$(( ${READ_LENGTH} / 2 )) ; fi

#=======================================================================================================
#
# PASS NUMBER OF THREADS TO 1 IF STEPS DOES NOT CONTAINS A "S"
#
#=======================================================================================================

if [[ ${STEPS} != *"M"* ]] &&  [[ ${STEPS} != *"V"* ]] ; then
	if [[ ${THREADS} -gt 1 ]] ; then echo -e "If you don't performe step M, use 1 threads !\n" ; exit ; fi
fi

#=======================================================================================================
#
# LOG FILE
#
#=======================================================================================================

if [[ "${OUTFASTQ_FWD}" != "XXX" ]] ; then
	OUTPUT=$( getDirname ${OUTFASTQ_FWD} )
	LOGFILE="${OUTPUT}/preprocessing.log"
else
	OUTPUT=$( getDirname ${FASTQ_FWD} )
	LOGFILE="${OUTPUT}/preprocessing.log"
fi


if [ -e ${LOGFILE} ] ; then rm ${LOGFILE} ; fi

echo -e "\nBEGIN FQPREPROC\n"

#=======================================================================================================
#
# PRINT INFORMATION
#
#=======================================================================================================

echo -e "Input reads (forward) : ${FASTQ_FWD}"
echo -e "Input reads reverse : ${FASTQ_REV}"
echo -e "forward output file name : ${OUTFASTQ_FWD}"
echo -e "reverse output file name : ${OUTFASTQ_REV}"
echo -e "singleton output file name : ${OUTFASTQ_SGL}"
echo -e "Steps : ${STEPS}"
echo -e "Quality score threshold : ${QUALITY_THRESHOLD}"
echo -e "Minimum read length threshold: ${MIN_READ_LENGTH}"
echo -e "Minimum percent of confident bases : ${PERCENT_CONFIDENT_BPS}"
echo -e "Maximum read length threshold : ${MAX_READ_LENGTH}"
echo -e "Number of bases to trim in 5' extremity : ${TRIM_LEFT}"
echo -e "Threads number: ${THREADS}"
echo -e "K-mers size: ${KMER_SIZE}"
echo -e "K-mers frequency : ${KMER_FREQ}"
echo -e "Clean files from MiSeQ step : ${CLEAN} (if 1 files are cleaned)\n"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================

STIME=${SECONDS}

#=======================================================================================================
#
# LAUNCHING SINGLE-END FASTQ CLEANING
#
#=======================================================================================================

if [ "${FASTQ_REV}" = "XXX" ] ; then

	NAME=${FASTQ_FWD%.*}
	INFILE=$( randomfile ${NAME} )
	OUTFILE=$( randomfile ${NAME} )

	echo -e "$( gettime ${STIME} ) BEGIN READING FILE ${FASTQ_FWD}"
	fq2sanger ${FASTQ_FWD} ${INFILE} ${LOGFILE}
	echo -e "$( gettime ${STIME} ) BEGIN READING FILE ${FASTQ_FWD}\n"

	echo "  read lengths = $READ_LENGTH" >> $LOGFILE ;
	echo "Launching fqPreproc:" >> $LOGFILE ;
	echo "  quality score threshold                 -q $QUALITY_THRESHOLD" >> $LOGFILE ;
	echo "  minimum read length                     -l $MIN_READ_LENGTH" >> $LOGFILE ;
	echo "  minimum percentage of confident bases   -p $PERCENT_CONFIDENT_BPS" >> $LOGFILE ;

	STEP_NB=${#STEPS}
	STEP_ID=0

	while [ ${STEP_ID} -lt ${STEP_NB} ]
	do
		STEP=${STEPS:$STEP_ID:1}

		case ${STEP} in

		A)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT ARTEFACTUAL READS"
			fqartfilter ${INFILE} ${OUTFILE}
			mv ${OUTFILE} ${INFILE}
			echo "Filtering out artifactual reads ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT ARTEFACTUAL READS\n"
			;;

		C)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : COUNTING READ NUMBER"
			CARD=$( fqsize ${INFILE} )
			echo "> number of reads: $card" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : COUNTING READ NUMBER\n"
			;;

		D)

			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : REMOVING DUPLICATED READS"
			fqnoduplicate_se ${INFILE} ${OUTFILE}
			mv ${OUTFILE} ${INFILE}
			echo "Filtering out duplicated reads ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : REMOVING DUPLICATED READS\n"
			;;

		F)

			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT READS CONTAINING TOO FEW CONFIDENT BASES"
			fqfilter ${INFILE} ${QUALITY_THRESHOLD} ${PERCENT_CONFIDENT_BPS} ${OUTFILE}
			mv ${OUTFILE} ${INFILE}
			echo "Filtering out non-confident reads ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT READS CONTAINING TOO FEW CONFIDENT BASES\n"
			;;

		L)

			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS IN 5' EXTREMITY AND/OR TO A FIXED LENGTH"
			if [[ -z ${TRIM_LEFT} ]] ; then L_OPTION="" ; else L_OPTION="-l ${TRIM_LEFT} " ; fi
			if [[ -z ${MAX_READ_LENGTH} ]] ; then X_OPTION="" ; else X_OPTION="-x ${MAX_READ_LENGTH} " ; fi
			mgx-seq-fqtrim -i ${INFILE} ${L_OPTION}${X_OPTION} > ${OUTFILE}
			mv ${OUTFILE} ${INFILE}
			echo "Trimming reads in 5' extremity and/or to a fixed length ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS IN 5' EXTREMITY AND/OR TO A FIXED LENGTH\n"

			;;

		M)
			echo -e "Preprocessing MiSeq not possible with single-ends reads\n"
			rm ${INFILE}
			exit

			;;

		T)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS"
			fqtrim_se ${INFILE} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${OUTFILE}
			mv $OUTFILE ${INFILE}
			mgx-seq-fqtrim -i ${INFILE} -n ${MIN_READ_LENGTH} > ${OUTFILE} # correct sickle v1.2 bug (some reads with a smaller lentgh than ${MIN_READ_LENGTH} are in the output file after filtering)
			mv ${OUTFILE} ${INFILE}
			echo "Trimming reads ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS\n"

			;;

		esac

		STEP_ID=$(( $STEP_ID + 1 ))

	done

	CARD_SINGLE=$( fqsize ${INFILE} )
	echo -e "> Number of single reads after preprocessing : ${CARD_SINGLE}"
	echo -e "single_reads_after_preprocessing\t${CARD_SINGLE}" >> ${LOGFILE}

	if [ "${OUTFASTQ_FWD}" = "XXX" ] ; then OUTFASTQ_FWD=${NAME}.${OUT}.fastq ; fi

	mv ${INFILE} ${OUTFASTQ_FWD}

	echo -e "$( gettime ${STIME} ) REMAINING SINGLE-ENDS READS WRITTEN INTO FILE ${OUTFASTQ_FWD}\n"

	chmod 775 ${OUTFASTQ_FWD}
	echo "Remaining single-ends reads written into file ${OUTFASTQ_FWD}" >> $LOGFILE
	echo "Total running time: $(gettime $STIME)" >> ${LOGFILE}
	chmod 775 ${LOGFILE}

	echo -e "$( gettime ${STIME} ) BEGIN RUNNING fastQC"

	if [ -e ${OUTFASTQ_FWD} ] ; then fastqc ${OUTFASTQ_FWD} ; fi

	echo -e "$( gettime ${STIME} ) END RUNNING fastQC\n"

#=======================================================================================================
#
# LAUNCHING PAIRED-END FASTQ CLEANING
#
#=======================================================================================================

else

	NAME_FWD=${FASTQ_FWD%.*}
	INFILE_FWD=$( randomfile ${NAME_FWD} )
	OUTFILE_FWD=$( randomfile ${NAME_FWD} )

	NAME_REV=${FASTQ_REV%.*}
	INFILE_REV=$( randomfile ${NAME_REV} )
	OUTFILE_REV=$( randomfile ${NAME_REV} )

	NAME_SGL=${NAME_FWD}
	OUTFILE_SGL=$( randomfile ${NAME_SGL} )

	echo -e "$( gettime ${STIME} ) BEGIN READING FILE ${FASTQ_FWD}"
	fq2sanger ${FASTQ_FWD} ${INFILE_FWD} ${LOGFILE}
	echo -e "$( gettime ${STIME} ) BEGIN READING FILE ${FASTQ_FWD}\n"
	echo -e "$( gettime ${STIME} ) BEGIN READING FILE ${FASTQ_REV}"
	fq2sanger ${FASTQ_REV} ${INFILE_REV} ${LOGFILE}
	echo -e "$( gettime ${STIME} ) END READING FILE ${FASTQ_REV}\n"
	echo "  read lengths = $READ_LENGTH" >> $LOGFILE ;
	echo "Launching fqPreproc:" >> $LOGFILE ;
	echo "  quality score threshold                 -q $QUALITY_THRESHOLD" >> $LOGFILE ;
	echo "  minimum read length                     -l $MIN_READ_LENGTH" >> $LOGFILE ;
	echo "  minimum percentage of confident bases   -p $PERCENT_CONFIDENT_BPS" >> $LOGFILE ;

	PE="true"

	STEP_NB=${#STEPS}
	STEP_ID=0

	while [ ${STEP_ID} -lt ${STEP_NB} ]
	do
		STEP=${STEPS:$STEP_ID:1}
		case ${STEP} in
		A)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT ARTEFACTUAL READS"
			fqartfilter ${INFILE_FWD} ${OUTFILE_FWD}
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			fqartfilter ${INFILE_REV} ${OUTFILE_REV}
			mv ${OUTFILE_REV} ${INFILE_REV}
			PE="false"
			echo "Filtering out artifactual reads ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT ARTEFACTUAL READS\n"
			;;

		C)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : COUNTING READ NUMBER"
			CARD_FWD=$( fqsize ${INFILE_FWD} )
			CARD_REV=$( fqsize ${INFILE_REV} )
			CARD_SGL=$( fqsize ${OUTFILE_SGL} )
			echo -e "\t> Number of reads : "
			echo -e "\t\t- forward : ${CARD_FWD}"
			echo -e "\t\t- reverse : ${CARD_REV}"
			echo -e "\t\t- singleton : ${CARD_SGL}"
			echo -e "\n> Number of reads :\n\t\t- forward : ${CARD_FWD}\n\t\t- reverse : ${CARD_REV}\n\t\t- singleton : ${CARD_SGL}"
			echo "> number of reads:  fwd=${CARD_FWD}  rev=${CARD_REV}  sgl=${CARD_SGL}" >> $LOGFILE
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : COUNTING READ NUMBER\n"
			;;

		D)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : REMOVING DUPLICATED READS"
			if [ "${PE}" = "false" ] ; then
				echo -e "$( gettime ${STIME} ) BEGIN INTERSECTIONG READS"
				fqintersect ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV} ${OUTFILE_SGL} A
				mv ${OUTFILE_FWD} ${INFILE_FWD}
				mv ${OUTFILE_REV} ${INFILE_REV}
				PE="true"
				echo "Intersecting reads ... [ok]" >> ${LOGFILE}
				echo -e "$( gettime ${STIME} ) END INTERSECTIONG READS\n"
			fi
			fqnoduplicate_pe ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV}
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			mv ${OUTFILE_REV} ${INFILE_REV}
			echo "Filtering out duplicated reads ... [ok]" >> $LOGFILE
			;;

		F)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT READS CONTAINING TOO FEW CONFIDENT BASES"
			fqfilter ${INFILE_FWD} ${QUALITY_THRESHOLD} ${PERCENT_CONFIDENT_BPS} ${OUTFILE_FWD}
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			fqfilter ${INFILE_REV} ${QUALITY_THRESHOLD} ${PERCENT_CONFIDENT_BPS} ${OUTFILE_REV}
			mv ${OUTFILE_REV} ${INFILE_REV}
			PE="false"
			echo "Filtering out non-confident reads ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : FILTERING OUT READS CONTAINING TOO FEW CONFIDENT BASES\n"

			;;

		L)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS IN 5' EXTREMITY AND/OR TO A FIXED LENGTH"
			if [ "${PE}" = "false" ] ; then
				echo -e "$( gettime ${STIME} ) BEGIN INTERSECTIONG READS"
				fqintersect ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV} ${OUTFILE_SGL} A
				mv ${OUTFILE_FWD} ${INFILE_FWD}
				mv ${OUTFILE_REV} ${INFILE_REV}
				PE="true"
				echo "Intersecting reads ... [ok]" >> ${LOGFILE}
				echo -e "$( gettime ${STIME} ) END INTERSECTIONG READS\n"
			fi
			if [[ -z ${TRIM_LEFT} ]] ; then L_OPTION="" ; else L_OPTION="-l ${TRIM_LEFT} " ; fi
			if [[ -z ${MAX_READ_LENGTH} ]] ; then X_OPTION="" ; else X_OPTION="-x ${MAX_READ_LENGTH} " ; fi
			mgx-seq-fqtrim -i ${INFILE_FWD} ${L_OPTION}${X_OPTION} > ${OUTFILE_FWD}
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			mgx-seq-fqtrim -i ${INFILE_REV} ${L_OPTION}${X_OPTION} > ${OUTFILE_REV}
			mv ${OUTFILE_REV} ${INFILE_REV}
			echo "Trimming reads in 5' extremity and/or to a fixed length ... [ok]" >> ${LOGFILE}
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS IN 5' EXTREMITY AND/OR TO A FIXED LENGTH\n"

			;;

		M)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : PREPROCESSING MISEQ\n"

			# FILTRAGE READS FWD
			echo -e "\t$( gettime ${STIME} ) BEGIN FILTERING FORWARD READS\n"
			getReadIDandSuffix ${INFILE_FWD}
			miseq_preproc ${THREADS} ${INFILE_FWD} ${OUTFILE_FWD} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${KMER_SIZE} ${KMER_FREQ} ${OUTPUT} ${CLEAN} ${STEPS}
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			TMP_INFILE_FWD=$( randomfile ${NAME_FWD})
			awk -v id=${ID} -v suffix="${SUFFIX}" '{ if ( $0 ~ id ) print $0" "suffix ; else print $0 ; }' ${INFILE_FWD} > ${TMP_INFILE_FWD}
			mv ${TMP_INFILE_FWD} ${INFILE_FWD}
			echo -e "\t$( gettime ${STIME} ) END FILTERING FORWARD READS\n"
			# FILTRAGE READS REV
			echo -e "\t$( gettime ${STIME} ) BEGIN FILTERING REVERSE READS\n"
			getReadIDandSuffix ${INFILE_REV}
			miseq_preproc ${THREADS} ${INFILE_REV} ${OUTFILE_REV} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${KMER_SIZE} ${KMER_FREQ} ${OUTPUT} ${CLEAN} ${STEPS}
			mv ${OUTFILE_REV} ${INFILE_REV}
			TMP_INFILE_REV=$( randomfile ${NAME_REV})
			awk -v id=${ID} -v suffix="${SUFFIX}" '{ if ( $0 ~ id ) print $0" "suffix ; else print $0 ; }' ${INFILE_REV} > ${TMP_INFILE_REV}
			mv ${TMP_INFILE_REV} ${INFILE_REV}
			echo -e "\t$( gettime ${STIME} ) END FILTERING REVERSE READS\n"
			# FILTRAGE SINGLETON SI DEJA PRESENT
			TMP_FILE_SGL=$( randomfile ${NAME_SGL})
			CARD_SGL=$( fqsize ${OUTFILE_SGL} )
			if [[ ${CARD_SGL} -gt 0 ]] ; then

				echo -e "\t$( gettime ${STIME} ) BEGIN FILTERING SINGLETON READS"
				miseq_preproc ${THREADS} ${OUTFILE_SGL} ${TMP_FILE_SGL} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${KMER_SIZE} ${KMER_FREQ} ${OUTPUT} ${CLEAN} ${STEPS}
				mv ${TMP_FILE_SGL} ${OUTFILE_SGL}
				echo -e "\t$( gettime ${STIME} ) END FILTERING SINGLETON READS\n"
			fi
			# INTERSECT REV AND FWD + ADD NEW SINGLETON
			echo -e "\t$( gettime ${STIME} ) BEGIN INTERSECT FORWARD AND REVERSE READS"
			fqintersect ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV} ${TMP_FILE_SGL} A
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			mv ${OUTFILE_REV} ${INFILE_REV}
			cat ${TMP_FILE_SGL} >> ${OUTFILE_SGL}
			echo -e "\t$( gettime ${STIME} ) END INTERSECT FORWARD AND REVERSE READS\n"
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : PREPROCESSING MISEQ\n"
			rm ${TMP_FILE_SGL}

			;;
		V)
			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : PREPROCESSING MISEQ WITHOUT ERROR CORRECTION\n"
			# FILTRAGE READS FWD
			echo -e "\t$( gettime ${STIME} ) BEGIN FILTERING FORWARD READS\n"
			getReadIDandSuffix ${INFILE_FWD}
			miseq_preproc ${THREADS} ${INFILE_FWD} ${OUTFILE_FWD} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${KMER_SIZE} ${KMER_FREQ} ${OUTPUT} ${CLEAN} ${STEPS}
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			TMP_INFILE_FWD=$( randomfile ${NAME_FWD})
			awk -v id=${ID} -v suffix="${SUFFIX}" '{ if ( $0 ~ id ) print $0" "suffix ; else print $0 ; }' ${INFILE_FWD} > ${TMP_INFILE_FWD}
			mv ${TMP_INFILE_FWD} ${INFILE_FWD}
			echo -e "\t$( gettime ${STIME} ) END FILTERING FORWARD READS\n"
			# FILTRAGE READS REV
			echo -e "\t$( gettime ${STIME} ) BEGIN FILTERING REVERSE READS\n"
			getReadIDandSuffix ${INFILE_REV}
			miseq_preproc ${THREADS} ${INFILE_REV} ${OUTFILE_REV} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${KMER_SIZE} ${KMER_FREQ} ${OUTPUT} ${CLEAN} ${STEPS}
			mv ${OUTFILE_REV} ${INFILE_REV}
			TMP_INFILE_REV=$( randomfile ${NAME_REV})
			awk -v id=${ID} -v suffix="${SUFFIX}" '{ if ( $0 ~ id ) print $0" "suffix ; else print $0 ; }' ${INFILE_REV} > ${TMP_INFILE_REV}
			mv ${TMP_INFILE_REV} ${INFILE_REV}
			echo -e "\t$( gettime ${STIME} ) END FILTERING REVERSE READS\n"
			# FILTRAGE SINGLETON SI DEJA PRESENT
			TMP_FILE_SGL=$( randomfile ${NAME_SGL})
			CARD_SGL=$( fqsize ${OUTFILE_SGL} )
			if [[ ${CARD_SGL} -gt 0 ]] ; then

				echo -e "\t$( gettime ${STIME} ) BEGIN FILTERING SINGLETON READS"
				miseq_preproc ${THREADS} ${OUTFILE_SGL} ${TMP_FILE_SGL} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${KMER_SIZE} ${KMER_FREQ} ${OUTPUT} ${CLEAN} ${STEPS}
				mv ${TMP_FILE_SGL} ${OUTFILE_SGL}
				echo -e "\t$( gettime ${STIME} ) END FILTERING SINGLETON READS\n"
			fi
			# INTERSECT REV AND FWD + ADD NEW SINGLETON
			echo -e "\t$( gettime ${STIME} ) BEGIN INTERSECT FORWARD AND REVERSE READS"
			fqintersect ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV} ${TMP_FILE_SGL} A
			mv ${OUTFILE_FWD} ${INFILE_FWD}
			mv ${OUTFILE_REV} ${INFILE_REV}
			cat ${TMP_FILE_SGL} >> ${OUTFILE_SGL}
			echo -e "\t$( gettime ${STIME} ) END INTERSECT FORWARD AND REVERSE READS\n"
			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : PREPROCESSING MISEQ\n"
			rm ${TMP_FILE_SGL}

			;;
		T)

			echo -e "$( gettime ${STIME} ) BEGIN STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS"

			if [ "${PE}" = "false" ] ; then

				echo -e "$( gettime ${STIME} ) BEGIN INTERSECTIONG READS"

				fqintersect ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV} ${OUTFILE_SGL} A
				mv ${OUTFILE_FWD} ${INFILE_FWD}
				mv ${OUTFILE_REV} ${INFILE_REV}
				PE="true"

				echo "Intersecting reads ... [ok]" >> ${LOGFILE}

				echo -e "$( gettime ${STIME} ) END INTERSECTIONG READS\n"

			fi

			TMP_FILE=$( randomfile ${NAME_SGL})

			fqtrim_pe ${INFILE_FWD} ${INFILE_REV} ${QUALITY_THRESHOLD} ${MIN_READ_LENGTH} ${OUTFILE_FWD} ${OUTFILE_REV} ${TMP_FILE}

			mv ${OUTFILE_FWD} ${INFILE_FWD}
			mv ${OUTFILE_REV} ${INFILE_REV}

			cat ${TMP_FILE} >> ${OUTFILE_SGL}

			mgx-seq-fqtrim -i ${INFILE_FWD} -n ${MIN_READ_LENGTH} > ${OUTFILE_FWD}	# correct sickle v1.2 bug (some reads with a smaller lentgh than ${MIN_READ_LENGTH} are in the output file after filtering)
			mgx-seq-fqtrim -i ${INFILE_REV} -n ${MIN_READ_LENGTH} > ${OUTFILE_REV}	# correct sickle v1.2 bug (some reads with a smaller lentgh than ${MIN_READ_LENGTH} are in the output file after filtering)
			mgx-seq-fqtrim -i ${OUTFILE_SGL} -n ${MIN_READ_LENGTH} > ${TMP_FILE}	# correct sickle v1.2 bug (some reads with a smaller lentgh than ${MIN_READ_LENGTH} are in the output file after filtering)

			mv ${OUTFILE_FWD} ${INFILE_FWD}
			mv ${OUTFILE_REV} ${INFILE_REV}

			cat ${TMP_FILE} > ${OUTFILE_SGL}

			rm ${TMP_FILE}

			echo "Trimming reads ... [ok]" >> ${LOGFILE}

			echo -e "$( gettime ${STIME} ) END STEP $(( ${STEP_ID} + 1 )) : TRIMMING READS\n"

			;;

		esac

		STEP_ID=$(( ${STEP_ID} + 1 ))

	done

	if [ "${PE}" = "false" ] ; then

		echo -e "$( gettime ${STIME} ) BEGIN INTERSECTING READS"

		fqintersect ${INFILE_FWD} ${INFILE_REV} ${OUTFILE_FWD} ${OUTFILE_REV} ${OUTFILE_SGL} A
		mv ${OUTFILE_FWD} ${INFILE_FWD}
		mv ${OUTFILE_REV} ${INFILE_REV}

		echo "Intersecting reads ... [ok]" >> ${LOGFILE}

		echo -e "$( gettime ${STIME} ) END INTERSECTING READS\n"

		STEP_ID=$(( ${STEP_ID} - 1 ))
		STEP=${STEPS:$STEP_ID:1}

		if [ "$STEP" = "C" ]
		then

			echo -n "> number of reads:"

			card_fwd=$(fqsize $INFILE_FWD)
			echo -n "  fwd=$card_fwd"

			card_rev=$(fqsize $INFILE_REV)
			echo -n "  rev=$card_rev"

			card_sgl=$(fqsize $OUTFILE_SGL)
			echo "  sgl=$card_sgl"

			echo "> number of reads:  fwd=$card_fwd  rev=$card_rev  sgl=$card_sgl" >> ${LOGFILE}

		fi

	fi

	if [ "${OUTFASTQ_FWD}" = "XXX" ] ; then OUTFASTQ_FWD=${NAME_FWD}.${OUT}.fastq ; fi
	mv ${INFILE_FWD} ${OUTFASTQ_FWD}
	chmod 775 ${OUTFASTQ_FWD}

	if [ "${OUTFASTQ_REV}" = "XXX" ] ; then OUTFASTQ_REV=${NAME_REV}.${OUT}.fastq ; fi
	mv ${INFILE_REV} ${OUTFASTQ_REV}
	chmod 775 ${OUTFASTQ_REV}

	echo -e "$( gettime ${STIME} ) REMAINING PAIRED-ENDS READS WRITTEN INTO FILES ${OUTFASTQ_FWD} AND ${OUTFASTQ_REV}\n"

	if [[ ${CARD_SGL} -gt 0 ]] ; then

		if [ "${OUTFASTQ_SGL}" = "XXX" ] ; then OUTFASTQ_SGL=${NAME_SGL}.${OUT}.sgl.fastq ; fi
		mv ${OUTFILE_SGL} ${OUTFASTQ_SGL}
		chmod 775 ${OUTFASTQ_SGL}
		echo -e "$( gettime ${STIME} ) REMAINING SINGLETON READS WRITTEN INTO FILE ${OUTFASTQ_SGL}\n"

	fi

	echo "Remaining paired-ends reads written into files $OUTFASTQ_FWD and $OUTFASTQ_REV" >> ${LOGFILE}
	echo "Single reads written into file $OUTFASTQ_SGL" >> ${LOGFILE}
	echo "Total running time: $(gettime $STIME)" >> ${LOGFILE}

	chmod 775 ${LOGFILE}

	echo -e "$( gettime ${STIME} ) BEGIN RUNNING fastQC"

	if [ -e ${OUTFASTQ_FWD} ] ; then echo -e "\t$( gettime ${STIME} ) BEGIN FORWARD READS" ; fastqc ${OUTFASTQ_FWD} ; echo -e "\t$( gettime ${STIME} ) END FORWARD READS" ; fi

	if [ -e ${OUTFASTQ_REV} ] ; then echo -e "\t$( gettime ${STIME} ) BEGIN REVERSE READS" ; fastqc ${OUTFASTQ_REV} ; echo -e "\t$( gettime ${STIME} ) END REVERSE READS" ; fi

	if [[ ${CARD_SGL} -gt 0 ]] ; then echo -e "\t$( gettime ${STIME} ) BEGIN SINGLETON READS" ; fastqc ${OUTFASTQ_SGL} ; echo -e "\t$( gettime ${STIME} ) END SINGLETON READS" ; fi

	echo -e "$( gettime ${STIME} ) END RUNNING fastQC\n"

fi

#=======================================================================================================
#
# STOPING TIMER
#
#=======================================================================================================

echo -e "Total running time for fqPreproc.sh : $( gettime ${FQPREPROC_TIME} ) (minutes:secondes)\n"

echo -e "END FQPREPROC\n"

exit 0

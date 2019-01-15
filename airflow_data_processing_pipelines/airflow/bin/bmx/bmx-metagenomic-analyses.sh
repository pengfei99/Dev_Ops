#! /bin/bash
# 09/03/15
# Thibaut Montagne
# Script to sample description(s) and comparisons if more than one sample is present in input text file (list of path to results pipeline directory)

echo -e "\n###############################\n#                             #\n# mgx-metagenomic-analyses.sh #\n#                             #\n###############################"

#=======================================================================================================
#
# STARTING TIMER
#
#=======================================================================================================

METAG_ANALYSES_TIME=${SECONDS}

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
cat << EOF

Options :
#########

-i 	Path to a config file (2 columns : path to result metag pipeline directory AND a label) (obligatory)
-o 	Path to an output directory for consolidated matrix (and comparison barplot if more than 1 sample)
-t 	Path to a taxoDB directory (obligatory)

Example of use :
###############

	mgx-metagenomic-analyses.sh -i INPUT_FILE -o OUTPUT_DIRECTORY -t TAXODIR -a ACTIONS

Theoretical data :
##################

	If you want to compare real results with theoretical result, you just have to create a directory with a _metag.txt file.

To do :
#######

 	- Handle sample labels with a "-" character

EOF
}

#=======================================================================================================
#
# GET THE PROGRAMM ARGUMENTS
#
#=======================================================================================================

while getopts "i:o:t:" PARAMETER
do
	case ${PARAMETER} in

		#  PATH VERS UN FICHIER DE CONF QUI CONTIENT LA LISTE DES PATH VERS LES REPERTOIRES DE RESULTATS DU PIPELINE --> LISTE A 2 COLONNES : PATH ET LABEL
		i) INPUT_FILE=${OPTARG};;

		# PATH VERS LE REPERTOIRE OU SERONT CREE LES MATRICES (ET LES DOSSIERS DATA ET FIGURES SI IL Y A PLUS D'UNE LIGNE DANS LA LISTE)
		o) OUTPUT_DIRECTORY=${OPTARG};;

		# PATH VERS LE REPERTOIRE DE LA TAXODB
		t) TAXODIR=${OPTARG};;

		:) echo " Option -${OPTARG} expects an argument " ; exit ;;
		\?) echo " Unvalid option ${OPTARG} " ; exit ;;
	esac
done

# PATH TO TAXODB
TAXODB=${TAXODIR}/ncbi-taxo.db

echo -e "\n##############\n# PARAMETERS #\n##############\n"
echo -e "\t--> Input          : ${INPUT_FILE}"
echo -e "\t--> Ouput          : ${OUTPUT_DIRECTORY}"
echo -e "\t--> TaxoDir        : ${TAXODIR}"
echo -e "\t--> TaxoDB         : ${TAXODB}"
if [[ ${LOG} -eq 0 ]] ; then echo -e "\t--> Log proportion : no" ; fi
if [[ ${LOG} -eq 1 ]] ; then echo -e "\t--> Log proportion : yes" ; fi

#=======================================================================================================
#
# OUTPUT DIRECTORIES
#
#=======================================================================================================

echo -e "\n###############################\n# OUTPUT DIRECTORIES CREATION #\n###############################\n"

echo -e "\t--> Create ${OUTPUT_DIRECTORY} directory"

# CREATION DU REPERTOIRE DE SORTIE
if [[ -d "${OUTPUT_DIRECTORY}" ]] ; then echo "Output directory already exist. Delete it or try another name ! " ; exit ; else mkdir -p ${OUTPUT_DIRECTORY} ; fi

echo -e "\n\t--> Create Data and Figures directory"

# CREATION REPERTOIRES DATA
mkdir ${OUTPUT_DIRECTORY}/Data

DATA=${OUTPUT_DIRECTORY}/Data

#=======================================================================================================
#
# READ LINES FROM INPUT FILE
#
#=======================================================================================================

echo -e "\n##############################\n# READ LINES FROM INPUT FILE #\n##############################\n"

echo "##############################################################################################"

# INITIALIZE LINE_NUMBER TO 0
LINE_NUMBER=0

# FOR EACH LINE OF INPUT FILE
while read DIRECTORY_PATH LABEL
do

	if [[ ${LABEL} == "" ]] ; then
		echo -e "\nProblème fichier de configuration : nom de échantillon absent\n"
		exit 1
	fi

	echo -e "\n\t--> Reading of sample ${LABEL} ..."

	# SEARCH _metag FILES IN ${DIRECTORY_PATH}
	FILE_METAG=$( find ${DIRECTORY_PATH} -name '*_metag.txt' )

	# SEARCH _allReads.txt IN ${DIRECTORY_PATH}
	FILE_READS=$( find ${DIRECTORY_PATH} -name '*_allReads.txt' )

	# SI LE FICHIER METAG EXISTE
	if [[ -f ${FILE_METAG} ]] ; then

		#ADD DIRECTORY DIRECTORY_PATH TO AN ARRAY OF PATHS
		echo -e "\n\t\t--> Add ${LABEL} sample path to an array of paths"
		TAB_DIRECTORY_PATHS[LINE_NUMBER]=${DIRECTORY_PATH}

		#AJOUT DU LABEL DANS LE TABLEAU DE LABELS
		echo -e "\n\t\t--> Add ${LABEL} sample label to an array of label"
		TAB_LABEL[LINE_NUMBER]=${LABEL}

		#AJOUT DU FICHIER DANS LE TABLEAU DE FICHIERS
		echo -e "\n\t\t--> Add ${LABEL} sample _metag.txt file to an array of _metag.txt files"
		TAB_METAG_FILES[LINE_NUMBER]=${FILE_METAG}

		echo -e "\n\t\t--> Add ${LABEL} sample number of mapped reads to an array of number of mapped reads"
		TAB_NUMBER_OF_MAPPED_READS[LINE_NUMBER]=$( awk -F $'\t' '{ SUM += $5 } END { print SUM }' ${FILE_METAG} )

		# IF allReads.txt EXISTS
		if [[ -f ${FILE_READS} ]] ; then
			echo -e "\n\t\t--> Add ${LABEL} sample total number of reads to an array of total number of reads"
			TAB_TOTAL_NUMBER_OF_READS[LINE_NUMBER]=$( cat ${FILE_READS} | wc -l )

		# IF NOT ( THEORETICAL CASES ) --> TOTAL NUMBER OF READS = NUMBER OF MAPPED READS
		else

			echo -e "\n\t\t--> Add ${LABEL} sample total number of reads to an array of total number of reads"
			echo -e "\n\t\t\tTHEORETICAL SAMPLE --> total number of reads = number of mapped reads"

			TAB_TOTAL_NUMBER_OF_READS[LINE_NUMBER]=${TAB_NUMBER_OF_MAPPED_READS[LINE_NUMBER]}

		fi

		# ON COMPTE LA LIGNE
		LINE_NUMBER=$(( ${LINE_NUMBER} + 1 ))

		echo -e "\n\t--> Reading of sample ${LABEL} OK\n"

		echo -e "##############################################################################################"

	else

		echo -e "\n\t\tWARNING : _metag.txt is missing for sample ${LABEL}\n"
		exit 1

	fi

done < ${INPUT_FILE}

#=======================================================================================================
#
# CONSOLIDATED MATRIX AND FILE STATS GENERATION
#
#=======================================================================================================

echo -e "\n#################################################\n# CONSOLIDATED MATRIX AND FILE STATS GENERATION #\n#################################################\n"

echo -e "\t--> _metag.txt files concatenation from _metag.txt array to ${DATA}/global.metag"
echo -e "\n\t--> stats.txt files concatenation from stats.txt array to ${DATA}/stats.txt"

for INDICE in $( seq 0 $(( ${LINE_NUMBER}-1 )) )
do

	METAG_FILE=${TAB_METAG_FILES[INDICE]}

	echo -e "\n\t\t--> concatenation of input files"
	echo -e "\n\t\t\t--> label change : ${TAB_LABEL[INDICE]}"
	# cat ${METAG_FILE} | sed -e "s/^[^\t]*\t\(.*\)$/${TAB_LABEL[INDICE]}\t\1/" >> ${DATA}/global.metag
	cat ${METAG_FILE} | awk -v new_label="${TAB_LABEL[INDICE]}" 'BEGIN{FS=OFS="\t"}{$1=new_label}1' >> ${DATA}/global.metag

	echo -e "${TAB_LABEL[INDICE]}\t${TAB_TOTAL_NUMBER_OF_READS[INDICE]}\t${TAB_NUMBER_OF_MAPPED_READS[INDICE]}" >> ${DATA}/stats.txt

done

# ON A ICI UN FICHIER global.metag GLOBAL AVEC TOUT LES .metag D'ORIGINE COLLES ET LE LABEL DU RUN EN PREMIERE COLONNE
# ON A EGALEMENT UN FICHIER STATS QUI SERA UTILE POUR LES SCRIPTS R

# MATRICE LCA
echo -e "\n\t--> Creation of lca matrix\n"
metag2matrixfull.pl < ${DATA}/global.metag > ${DATA}/global.metag.matrix

cut -f1-3 ${DATA}/global.metag.matrix > ${DATA}/metag1.tmp 
cut -f1 ${DATA}/global.metag.matrix | sed "s/taxid/seqid/" > ${DATA}/metag3.tmp 
cut -f4- ${DATA}/global.metag.matrix > ${DATA}/metag2.tmp 
paste ${DATA}/metag1.tmp ${DATA}/metag3.tmp ${DATA}/metag2.tmp >  ${DATA}/row_matrix_normalized.metag
rm ${DATA}/metag1.tmp ${DATA}/metag3.tmp ${DATA}/metag2.tmp
# MATRICE CONSOLIDEE
echo -e "\n\t--> Creation of consolidated matrix"
matrixconsolidated.pl -m ${DATA}/global.metag.matrix -names ${TAXODIR}/names.dmp -nodes ${TAXODIR}/nodes.dmp -o ${DATA}/global.metag.matrixconsolidated

# MATRICE CLEAN CONSOLIDEE
echo -e "\n\t--> Creation of clean consolidated matrix"
cat ${DATA}/global.metag.matrixconsolidated | sed -e "s/#/_/g" | sed -e "s/ /_/g" | sed -e "s/\./_/g" | sed -e "s/-/_/g" | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/'//g" | sed -e "s/\///g"  | sed -e "s/(//g" | sed -e "s/)//g" | sed -e "s/=//g" | sed -e "s/\+//g" | sed -e "s/\"//g" | sed -e "s/,//g" | sed -e "s/://g" | sed -e "s/99260\tno_rank\tenvironmental_samples/99260\tno_rank\tenvironmental_samples99260/g" | sed -e "s/class\tActinobacteria/class\tActinobacteria_class/g" | sed -e "s/class\tAquificae/class\tAquificae_class/g" | sed -e "s/class\tChloroflexi/class\tChloroflexi_class/g" | sed -e "s/class\tChrysiogenetes/class\tChrysiogenetes_class/g" | sed -e "s/class\tDeferribacteres/class\tDeferribacteres_class/g" | sed -e "s/class\tGemmatimonadetes/class\tGemmatimonadetes_class/g" | sed -e "s/class\tNitrospira/class\tNitrospira_class/g" | sed -e "s/class\tThermotogae/class\tThermotogae_class/g" | sed -e "s/class\tElusimicrobia/class\tElusimicrobia_class/g" | sed -e "s/subgenus\tMoraxella/subgenus\tMoraxella_subgenus/g" > ${DATA}/global.metag.clean.matrixconsolidated


#=======================================================================================================
#
# STOPING TIMER
#
#=======================================================================================================

echo -e "Total running time for mgx-metagenomic-analyses.sh : $( gettime ${METAG_ANALYSES_TIME} ) (minutes:secondes)\n"

echo -e "################################\n#                              #\n# END OF METAGENOMICS ANALYSES #\n#                              #\n################################\n"

exit 0


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
-a	2-character string to choose actions to perform. (obligatory)
		00 : Individual and comparison sample analyses. Data and figures generated
		01 : Individual and comparison sample analyses. Only data generated

		10 : Only individual sample analyses. Data and figures generated
		11 : Only individual sample analyses. Only data generated

		20 : Only comparison sample analyses. Data and figures generated
		21 : Only comparison sample analyses. Only data generated
-l	Log proportions or not for second comparison plot (0 no, 1 yes)

Example of use :
###############

	mgx-metagenomic-analyses.sh -i INPUT_FILE -o OUTPUT_DIRECTORY -t TAXODIR -a ACTIONS

Theoretical data :
##################

	If you want to compare real results with theoretical result, you just have to create a directory with a _metag.txt file.

Dependencies :
##############

	Add "/Projets/PRG0092-Sequencing/B2129-High_Throughput_Sequencing_Platform/Tools/src/KronaTools-2.4/scripts" in your PERL5LIB variable.

To do :
#######

 	- Handle sample labels with a "-" character

EOF
}

#=======================================================================================================
#
# DEPENDENCIES
#
#=======================================================================================================

# PATH TO KRONA
KRONA="/Projets/PRG0092-Sequencing/B2129-High_Throughput_Sequencing_Platform/Tools/src/KronaTools-2.4/scripts"

#=======================================================================================================
#
# BY DEFAULT VALUES
#
#=======================================================================================================

#PATH TO TAXO DIRECTORY
TAXODIR="/Master_Data/BioTaxon/NCBI_Taxonomy/20141230"

#=======================================================================================================
#
# GET THE PROGRAMM ARGUMENTS
#
#=======================================================================================================

while getopts "i:o:t:a:l:" PARAMETER
do
	case ${PARAMETER} in

		#  PATH VERS UN FICHIER DE CONF QUI CONTIENT LA LISTE DES PATH VERS LES REPERTOIRES DE RESULTATS DU PIPELINE --> LISTE A 2 COLONNES : PATH ET LABEL
		i) INPUT_FILE=${OPTARG};;

		# PATH VERS LE REPERTOIRE OU SERONT CREE LES MATRICES (ET LES DOSSIERS DATA ET FIGURES SI IL Y A PLUS D'UNE LIGNE DANS LA LISTE)
		o) OUTPUT_DIRECTORY=${OPTARG};;

		# PATH VERS LE REPERTOIRE DE LA TAXODB
		t) TAXODIR=${OPTARG};;

		# STRING TO CHOOSE ACTIONS TO PERFORM
		a) ACTIONS=${OPTARG};;

		# LOG PROPORTIONS OR NOT FOR SECOND COMPARISON PLOT (0 : NO, 1 : YES)
		l) LOG=${OPTARG};;

		:) echo " Option -${OPTARG} expects an argument " ; exit ;;
		\?) echo " Unvalid option ${OPTARG} " ; exit ;;
	esac
done

#=======================================================================================================
#
# USAGE RESTRICTIONS TESTS
#
#=======================================================================================================

# SI IL MANQUE UN PARAMETRE
if [[ -z ${INPUT_FILE} || -z ${OUTPUT_DIRECTORY} || -z ${TAXODIR} || -z ${ACTIONS} || -z ${LOG} ]] ; then usage ; exit 1 ; fi

# LENGTH OF ACTIONS STRING. MUST BE 2
LENGTH=${#ACTIONS}

# TEST IF LENGTH IS 2 OR NOT
if [[ ${LENGTH} -lt 2 || ${LENGTH} -gt 2 ]] ; then echo "Option -a must be 00, 01, 10, 11, 20 or 21" ; exit ; else

	# ACTION1
	# 	0 : individual + comparison sample analyse
	# 	1 : individual sample only
	# 	2 : comparison sample only

	# ACTION2
	# 	0 : data + figure
	# 	1 : data only

	ACTION1=${ACTIONS:0:1}
	ACTION2=${ACTIONS:1:1}

	# TEST IF ACTION1 IS 0, 1, OR 2. EXIT IF NOT
	if [[ ${ACTION1} -lt 0 || ${ACTION1} -gt 2 ]] ; then echo "Action 1 must be 0, 1 or 2" ; exit ; fi

	# TEST IF ACTION2 IS 0 OR 1. EXIT IF NOT
	if [[ ${ACTION2} -lt 0 || ${ACTION2} -gt 1 ]] ; then echo "Action 2 must be 0 or 1" ; exit ; fi

	if [[ ${ACTION1} -eq 0 && ${ACTION2} -eq 0 ]] ; then CHOICE="Individual and comparison sample analyses. Data and figures generated." ; fi
	if [[ ${ACTION1} -eq 0 && ${ACTION2} -eq 1 ]] ; then CHOICE="Individual and comparison sample analyses. Only data generated." ; fi
	if [[ ${ACTION1} -eq 1 && ${ACTION2} -eq 0 ]] ; then CHOICE="Only individual sample analyses. Data and figures generated." ; fi
	if [[ ${ACTION1} -eq 1 && ${ACTION2} -eq 1 ]] ; then CHOICE="Only individual sample analyses. Only data generated." ; fi
	if [[ ${ACTION1} -eq 2 && ${ACTION2} -eq 0 ]] ; then CHOICE="Only comparison sample analyses. Data and figures generate.d" ; fi
	if [[ ${ACTION1} -eq 2 && ${ACTION2} -eq 1 ]] ; then CHOICE="Only comparison sample analyses. Only data generated." ; fi

fi

if [[ ${LOG} -lt 0 || ${LOG} -gt 1 ]] ; then echo "Option -l must be 0 (not log) or 1 (log)" ; exit ; fi

# PATH TO TAXODB
TAXODB=${TAXODIR}/ncbi-taxo.db

echo -e "\n##############\n# PARAMETERS #\n##############\n"
echo -e "\t--> Input          : ${INPUT_FILE}"
echo -e "\t--> Ouput          : ${OUTPUT_DIRECTORY}"
echo -e "\t--> TaxoDir        : ${TAXODIR}"
echo -e "\t--> TaxoDB         : ${TAXODB}"
echo -e "\t--> Actions        : ${CHOICE}"
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
if [[ -d "${OUTPUT_DIRECTORY}" ]] ; then echo "Output directory already exist. Delete it or try another name ! " ; exit ; else mkdir ${OUTPUT_DIRECTORY} ; fi

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

# MATRICE CONSOLIDEE
echo -e "\n\t--> Creation of consolidated matrix"
matrixconsolidated.pl -m ${DATA}/global.metag.matrix -names ${TAXODIR}/names.dmp -nodes ${TAXODIR}/nodes.dmp -o ${DATA}/global.metag.matrixconsolidated

# MATRICE CLEAN CONSOLIDEE
echo -e "\n\t--> Creation of clean consolidated matrix"
cat ${DATA}/global.metag.matrixconsolidated | sed -e "s/#/_/g" | sed -e "s/ /_/g" | sed -e "s/\./_/g" | sed -e "s/-/_/g" | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/'//g" | sed -e "s/\///g"  | sed -e "s/(//g" | sed -e "s/)//g" | sed -e "s/=//g" | sed -e "s/\+//g" | sed -e "s/\"//g" | sed -e "s/,//g" | sed -e "s/://g" | sed -e "s/99260\tno_rank\tenvironmental_samples/99260\tno_rank\tenvironmental_samples99260/g" | sed -e "s/class\tActinobacteria/class\tActinobacteria_class/g" | sed -e "s/class\tAquificae/class\tAquificae_class/g" | sed -e "s/class\tChloroflexi/class\tChloroflexi_class/g" | sed -e "s/class\tChrysiogenetes/class\tChrysiogenetes_class/g" | sed -e "s/class\tDeferribacteres/class\tDeferribacteres_class/g" | sed -e "s/class\tGemmatimonadetes/class\tGemmatimonadetes_class/g" | sed -e "s/class\tNitrospira/class\tNitrospira_class/g" | sed -e "s/class\tThermotogae/class\tThermotogae_class/g" | sed -e "s/class\tElusimicrobia/class\tElusimicrobia_class/g" | sed -e "s/subgenus\tMoraxella/subgenus\tMoraxella_subgenus/g" > ${DATA}/global.metag.clean.matrixconsolidated

#=======================================================================================================
#
# INDIVIDUAL SAMPLE ANALYSES
#
#=======================================================================================================

if [[ ${ACTION1} -eq 0 || ${ACTION1} -eq 1 ]] ; then

	echo -e "\n##############################\n# INDIVIDUAL SAMPLE ANALYSES #\n##############################\n"

	for INDICE in $( seq 0 $(( ${LINE_NUMBER}-1 )) )
	do

		DIRECTORY_PATH=${TAB_DIRECTORY_PATHS[INDICE]}
		LABEL=${TAB_LABEL[INDICE]}
		FILE_METAG=${TAB_METAG_FILES[INDICE]}

		echo -e "\t--> Analyse of sample ${LABEL} ..."

		#ON CREE LES REPERTOIRE DATA ET FIGURES
		if [[ -d "${OUTPUT_DIRECTORY}/${LABEL}" ]]; then
			rm -r ${OUTPUT_DIRECTORY}/${LABEL}
			mkdir ${OUTPUT_DIRECTORY}/${LABEL}
		else
			mkdir ${OUTPUT_DIRECTORY}/${LABEL}
		fi

		cp ${DIRECTORY_PATH}/summary.txt ${OUTPUT_DIRECTORY}/${LABEL}/summary.txt

		echo -e "\n\t\t--> Create Data and Figures directories"

		#ON CREE LES REPERTOIRE DATA ET FIGURES
		if [[ -d "${OUTPUT_DIRECTORY}/${LABEL}/Data" ]]; then
			rm -r ${OUTPUT_DIRECTORY}/${LABEL}/Data
			mkdir ${OUTPUT_DIRECTORY}/${LABEL}/Data
		else
			mkdir ${OUTPUT_DIRECTORY}/${LABEL}/Data
		fi

		if [[ -d "${OUTPUT_DIRECTORY}/${LABEL}/Figures" ]]; then
			rm -r ${OUTPUT_DIRECTORY}/${LABEL}/Figures
			mkdir ${OUTPUT_DIRECTORY}/${LABEL}/Figures
		else
			mkdir ${OUTPUT_DIRECTORY}/${LABEL}/Figures
		fi

		SAMPLE_DATA=${OUTPUT_DIRECTORY}/${LABEL}/Data
		SAMPLE_FIGURES=${OUTPUT_DIRECTORY}/${LABEL}/Figures

		# EXTRACTION COLONNE 2 ET 5 POUR FICHIER TAXO_COUNT
		echo -e "\n\t\t--> Generation taxocount file : extraction column 2 and 5 from metag file of sample ${LABEL} (awk)"
		awk -F $'\t' '{ printf("%s %s\n", $2, $5) }' ${FILE_METAG} > ${SAMPLE_DATA}/${LABEL}_taxocount.txt

		# STAT RANK METASEE
		echo -e "\n\t\t--> Generation of krona text file for the sample ${LABEL} (mgx-taxo-stat)"
		mgx-taxo-stat -t ${TAXODB} -i ${SAMPLE_DATA}/${LABEL}_taxocount.txt -o ${SAMPLE_DATA}/${LABEL}_krona.txt --rank --metasee 1> ${SAMPLE_DATA}/${LABEL}_taxocount_rank.txt

		if [[ ${ACTION2} -eq 0 ]] ; then

			# GENERATION KRONA
			echo -e "\n\t\t--> Creation representation krona of sample ${LABEL} (Krona)\n"
			perl ${KRONA}/ImportText.pl -n cellular_organisms ${SAMPLE_DATA}/${LABEL}_krona.txt -o ${SAMPLE_FIGURES}/${LABEL}_krona.html

		fi

		#GENERATION DATA ET/OU FIGURES (BARPLOT) READ PAR TAXON A CHAQUE NIVEAU TAXO
		echo -e "\n\t\t--> Generation barplot of sample ${LABEL} (mgx-metagenomic-barplots-reads-per-taxon.R)\n"
		echo -e "mgx-metagenomic-barplots-reads-per-taxon.R ${DATA}/global.metag.clean.matrixconsolidated ${DATA}/stats.txt ${SAMPLE_FIGURES}/${LABEL}_barplot.pdf ${SAMPLE_DATA}/${LABEL}_barplot.data ${ACTION2} ${LABEL}\n"
		mgx-metagenomic-barplots-reads-per-taxon.R ${DATA}/global.metag.clean.matrixconsolidated ${DATA}/stats.txt ${SAMPLE_FIGURES}/${LABEL}_barplot.pdf ${SAMPLE_DATA}/${LABEL}_barplot.data ${ACTION2} ${LABEL}

		echo -e "\t--> Analyse of sample ${LABEL} OK\n"

		echo -e "##############################################################################################\n"

	done

fi

#=======================================================================================================
#
# COMPARISON SAMPLE ANALYSES
#
#=======================================================================================================

if [[ ${ACTION1} -eq 0  || ${ACTION1} -eq 2 ]] ; then

	if [[ -d "${OUTPUT_DIRECTORY}/ComparaisonEchantillons" ]] ; then
		rm -r ${OUTPUT_DIRECTORY}/ComparaisonEchantillons
		mkdir ${OUTPUT_DIRECTORY}/ComparaisonEchantillons
	else
		mkdir ${OUTPUT_DIRECTORY}/ComparaisonEchantillons
	fi

	COMPARAISON=${OUTPUT_DIRECTORY}/ComparaisonEchantillons

	echo -e "\n##############################\n# COMPARISON SAMPLE ANALYSES #\n##############################\n"

	# SI IL Y A PLUS D'UNE LIGNE DANS LE FICHIER (CAD SI IL Y A PLUS D'UN ECHANTILLON)
	if [[ ${LINE_NUMBER} -gt 1 ]] ; then

		echo -e "\t--> ${LINE_NUMBER} samples to compare"

		# GENERATION DATA ET/OU FIGURES (BARPLOT) DE COMPARAISON D'ECHANTILLONS
		echo -e "\n\t--> Sample comparison data and/or barplot generation\n"
		echo -e "mgx-metagenomic-barplots.R ${DATA}/global.metag.clean.matrixconsolidated ${DATA}/stats.txt ${COMPARAISON}/sample_comparison.pdf ${DATA}/global_barplot.data ${ACTION2}\n"
		mgx-metagenomic-barplots.R ${DATA}/global.metag.clean.matrixconsolidated ${DATA}/stats.txt ${COMPARAISON}/sample_comparison1.pdf ${DATA}/global_barplot.data ${ACTION2}
		echo -e "mgx-metagenomic-sample-comparison.R ${DATA}/global.metag.clean.matrixconsolidated ${DATA}/stats.txt ${COMPARAISON}/sample_comparison2.pdf ${ACTION2} ${LOG}\n"
		mgx-metagenomic-sample-comparison.R ${DATA}/global.metag.clean.matrixconsolidated ${DATA}/stats.txt ${COMPARAISON}/sample_comparison2.pdf ${ACTION2} ${LOG}

	else

		echo -e "\tOnly one sample in the list. Comparison impossible !\n"

	fi

fi

#=======================================================================================================
#
# STOPING TIMER
#
#=======================================================================================================

echo -e "Total running time for mgx-metagenomic-analyses.sh : $( gettime ${METAG_ANALYSES_TIME} ) (minutes:secondes)\n"

echo -e "################################\n#                              #\n# END OF METAGENOMICS ANALYSES #\n#                              #\n################################\n"

exit 0

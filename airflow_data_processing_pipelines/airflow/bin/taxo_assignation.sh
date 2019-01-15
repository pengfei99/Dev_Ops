#!/bin/bash

# $1 project directory $2 java bin path
# parameters
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/rep_set.fna
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/outRDP_assign.txt
db_path="/mnt/gpfs/pt2/Genomes/SILVA_db/SILVA123_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S_withoutUncultured_84425.fasta"
taxRdp_path="/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/silva_openref_vsearch_params_taxrdp.txt"
rdp_training="/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/RDP_training_CLEAN/RdpClassifier.properties"
threads=6



# java commands, if you don't have java in your path, you need to specify it in $3, if you don't have trimmomatic-0.36.jar in your path, you need to specify it in $2

# db is not define, 
java -Xmx3024m -jar $2/rdp_classifier-2.2.jar -f db -o $output -t $rdp_training -q $input

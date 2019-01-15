#!/bin/bash

#$1 is projectPath, $2 is the bin path of matrix consolidation
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/Normalized_matrix.txt
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/Consolidated_matrix.txt
taxonomy_nodes="/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/RDP_training_CLEAN/nodes_RDPsilva.dmp"
taxonomy_names="/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/RDP_training_CLEAN/names_RDPsilva.dmp"

source ~/.bashrc
cat $input | cut -f1,2,3,5- > $input"v2" ; $2/matrixconsolidated.pl -m $input"v2" -names $taxonomy_names -nodes $taxonomy_nodes -o $output

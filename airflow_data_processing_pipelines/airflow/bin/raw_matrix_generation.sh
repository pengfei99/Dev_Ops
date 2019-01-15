#!/bin/bash

#$1 is projectPath, $2 is the bin path of Biom_to_rawmatrix
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/otu_table_filtered.biom.json
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/Rawmatrix.txt
taxonomy_infos="/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/RDP_training_CLEAN/tax_info_taxid_rank_taxname_CLEAN.R"
	
Rscript $2/BIOM_to_Rawmatrix.R $input $taxonomy_infos $output

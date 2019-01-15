#!/bin/bash

#$1 is projectPath, $2 is the bin path of matrix normalization
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/Rawmatrix.txt
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/Normalized_matrix.txt

Rscript $2/Rawmatrix_normalization.R $input $output

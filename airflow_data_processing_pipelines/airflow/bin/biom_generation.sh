#!/bin/bash

#$1 is projectPath 
output_dir_path=$1/tmp
input_assign=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/outRDP_assign.txt
input_otu_map=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/final_otu_map_mc2.txt
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/otu_table.biom

cat $input_assign  | cut -f1,3,4 > $input_assign"v2" ; make_otu_table.py -i $input_otu_map -o $output -t $input_assign"v2"

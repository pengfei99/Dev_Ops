#!/bin/bash

#$1 is projectPath
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/otu_table_filtered.biom
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/otu_table_filtered.biom.json

biom convert -i $input -o $output --to-json

#!/bin/bash

#$1 is projectPath
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/otu_table.biom
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/otu_table_filtered.biom
minfraction="0.00005"

filter_otus_from_otu_table.py -i $input -o $output --min_count_fraction $minfraction

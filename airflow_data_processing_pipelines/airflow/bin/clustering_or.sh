#!/bin/bash

#$1 is projectPath $2 is python bin path
# db_path and taxRdp_path needs to be defined
db_path="/mnt/gpfs/pt2/Genomes/SILVA_db/SILVA123_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S_withoutUncultured_84425.fasta"
taxRdp_path="/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/silva_openref_vsearch_params_taxrdp.txt"
threads=6
parent_dir_path=$1/tmp/QIIME_analysis
input=$parent_dir_path/seqs.fasta
output_otu_map=$parent_dir_path/openref_vsearch_taxrdp_otus/final_otu_map_mc2.txt
output_rep_set=$parent_dir_path/openref_vsearch_taxrdp_otus/rep_set.fna
output=$parent_dir_path/openref_vsearch_taxrdp_otus

$2/pick_open_reference_otus.py -i $input -m usearch61  --suppress_step4 --suppress_taxonomy_assignment --suppress_align_and_tree -o $output -r $db_path  -p $taxRdp_path -f

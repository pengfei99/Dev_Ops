#!/bin/bash

#$1 is projectPath $2 is qiime bin path
output_dir_path=$1/tmp
input=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/rep_set.fna
output=$output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/rep_set.tre
core_alignment=/mnt/gpfs/pt2/Genomes/SILVA_db/SILVA123_QIIME_release/core_alignment/core_alignment_SILVA123.fasta
	
$2/align_seqs.py -i $input -t $core_alignment -o $output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/pynast_aligned_seq ; filter_alignment.py -o $output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/pynast_aligned_seq -i $output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/pynast_aligned_seq/rep_set_aligned.fasta ; make_phylogeny.py -i $output_dir_path/QIIME_analysis/openref_vsearch_taxrdp_otus/pynast_aligned_seq/rep_set_aligned_pfiltered.fasta -o $output

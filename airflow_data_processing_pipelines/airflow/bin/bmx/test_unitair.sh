#!/bin/bash

#step 1. bmx_preproc
sample_name=$1
project_dir=/mnt/gpfs/pt6/airflow/projects/4
conf_path=$project_dir/metag_pipeline_short16S.cfg
read_1=$project_dir"/Rawdata/"$sample_name"_R1.fastq"
read_2=$project_dir"/Rawdata/"$sample_name"_R2.fastq"
output=$project_dir/output/$sample_name
result=$project_dir/output/analysis
sample_mapping_list=$project_dir/sample_mapping_list.txt
source /mnt/gpfs/pt6/airflow/bin/bmx/package_metaseq/env-package.sh

#mkdir -p $output

#sh bmx_preproc.sh -c $conf_path -i $read_1 -I $read_2 -o $output
#sh bmx_merge.sh -c $conf_path -i $read_1 -I $read_2 -o $output
#sh bmx_mapping.sh -c $conf_path -i $read_1 -o $output
#sh bmx_merge_bam.sh -c $conf_path -i $read_1 -o $output
#sh bmx_lca.sh -c $conf_path -i $read_1 -I $read_2 -o $output

sh bmx-metagenomic-analyses.sh -i $sample_mapping_list -o $result -t /mnt/gpfs/pt6/airflow/bmx_pipeline_dependencies/NCBI_Taxonomy/20170223

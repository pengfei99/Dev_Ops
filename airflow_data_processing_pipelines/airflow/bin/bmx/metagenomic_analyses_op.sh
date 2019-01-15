#!/bin/bash

#step 1. bmx_preprocessing, $1 is the project directory, $2 is the set env bin path
project_dir=$1
result=$project_dir/output/analysis
sample_mapping_list=$project_dir/sample_mapping_list.txt
ncbi_db_path=/mnt/gpfs/pt6/airflow/bmx_pipeline_dependencies/NCBI_Taxonomy/20170223

source $2

sh /mnt/gpfs/pt6/airflow/bin/bmx/bmx-metagenomic-analyses.sh -i $sample_mapping_list -o $result -t $ncbi_db_path

#!/bin/bash

#step 1. bmx_preprocessing, $1 is the project directory, $2 is the sample name, $3 is conf file, $4 is the env set up script
conf_path=$3
sample_name=$2
project_dir=$1
read_1=$project_dir"/Rawdata/"$sample_name"_R1.fastq"
read_2=$project_dir"/Rawdata/"$sample_name"_R2.fastq"
output=$project_dir/output/$sample_name

source $4

#sh bmx_preproc.sh -c $conf_path -i $read_1 -I $read_2 -o $output
sh /mnt/gpfs/pt6/airflow/bin/bmx/bmx_merge.sh -c $conf_path -i $read_1 -I $read_2 -o $output
#sh bmx_mapping.sh -c $conf_path -i $read_1 -o $output
#sh bmx_merge_bam.sh -c $conf_path -i $read_1 -o $output

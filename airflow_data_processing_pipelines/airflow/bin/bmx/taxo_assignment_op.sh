#!/bin/bash

#step 1. bmx_preprocessing, $1 is the project directory, $2 is the sample name, $3 is conf file
conf_path=$3
sample_name=$2
project_dir=$1
read_1=$project_dir"/Rawdata/"$sample_name"_R1.fastq"
read_2=$project_dir"/Rawdata/"$sample_name"_R2.fastq"
output=$project_dir/output/$sample_name

source $4

sh /mnt/gpfs/pt6/airflow/bin/bmx/bmx_lca.sh -c $conf_path -i $read_1 -I $read_2 -o $output

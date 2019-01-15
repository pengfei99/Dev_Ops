#!/bin/bash

# $1 is the project dir, $2 is the sample name $3 is fastqc bin path $4 is the dag_id
input_dir_path=$1/tmp/preprocessing
input=$input_dir_path/$2"_PEAR.assembled_trimmo_SGA.fastq"
tmp_dir_path=$1/tmp
result_dir_path=$1/$4"_results"
output=$tmp_dir_path/FastQC/$2_PEAR.assembled_trimmo_SGA_fastqc.html
threads=1

#echo $input $output $result_dir_path/Summary
mkdir -p $tmp_dir_path/FastQC $result_dir_path/Summary
$3/fastqc $input -t $threads --extract -o $tmp_dir_path/FastQC
mv $tmp_dir_path/FastQC/$2'_PEAR.assembled_trimmo_SGA_fastqc/summary.txt'  $result_dir_path'/Summary/'$2'.txt'


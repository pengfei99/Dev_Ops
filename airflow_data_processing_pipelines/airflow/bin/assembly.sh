#!/bin/bash

#$1 is projectPath $2 is sample_name $3 is pear bin path (can be ommited if pear is in user path)

min_assembly_length="300"
max_assembly_length="550"
min_overlap="10"
max_uncalled_bases="0"
output_dir_path=$1/tmp/preprocessing
output_prefix=$output_dir_path/$2_PEAR
reads1=$1/Rawdata/$2_R1.fastq
reads2=$1/Rawdata/$2_R2.fastq
log_path=$output_dir_path/$2_PEAR\.log
threads=4

# create output dir 
mkdir -p "$output_dir_path"

# if pear is not in current user path, you need to use $3/pear instead of pear 
$3/pear -f $reads1 -r $reads2 -v $min_overlap -m $max_assembly_length -n $min_assembly_length -u $max_uncalled_bases -j $threads -o $output_prefix 2>&1 | tee $log_path


#!/bin/bash

#$1 is projectPath $2 is sample_name $3 is sga bin path
MINLEN=100
quality_filter=20
QUAL=30
threads=4
output_dir_path=$1/tmp/preprocessing
input=$output_dir_path/$2_PEAR.assembled_trimmo.fastq
output=$output_dir_path/$2_PEAR.assembled_trimmo_SGA.fastq

$3/sga preprocess -q $QUAL -f $quality_filter -m $MINLEN --pe-mode=0 -o $output $input

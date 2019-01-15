#!/bin/bash

#$1 is projectPath, $2 is sample_name, $3 is java bin path, $4 is trimmomatic-0.36.jar path 

# parameters
output_dir_path=$1/tmp/preprocessing
input=$output_dir_path/$2_PEAR.assembled.fastq
output=$output_dir_path/$2_PEAR.assembled_trimmo.fastq
log=$output_dir_path/$2_trimmomatic\.log
MINLEN=100
LEADING=3
TRAILING=3
SLIDINGWINDOW=4
QUAL=15
threads=4



# java commands, if you don't have java in your path, you need to specify it in $3, if you don't have trimmomatic-0.36.jar in your path, you need to specify it in $4

java -jar $3/trimmomatic-0.36.jar SE -threads $threads -trimlog $log $input $output SLIDINGWINDOW:$SLIDINGWINDOW:$QUAL LEADING:$LEADING TRAILING:$TRAILING MINLEN:$MINLEN


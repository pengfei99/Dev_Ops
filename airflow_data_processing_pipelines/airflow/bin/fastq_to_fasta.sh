#!/bin/bash

#$1 is projectPath $2 is sample_name $3 is fastq-to-fasta executable path
output_dir_path=$1/tmp/preprocessing
input=$output_dir_path/$2_PEAR.assembled_trimmo_SGA.fastq
output=$output_dir_path/$2_PEAR.assembled_trimmo_SGA.fasta

# Command transform fastq to fats, if fastq-to-fasta is not in your path, you need to use $3 as path of it.

cat $input | $3/fastq-to-fasta | sed -r 's/^>/>'$2'_/g' > $output


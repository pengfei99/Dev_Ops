!#/bin/bash

#Step 1 unzip

#Step 2 
sh assembly.sh /mnt/gpfs/pt6/airflow/projects/2 S3 /mnt/gpfs/pt2/Apps/CentOS7/PEAR/bin

#task 7
sh clustering_or.sh /mnt/gpfs/pt6/airflow/projects/2 /mnt/gpfs/pt2/Apps/CentOS7/Qiime

#task 13
sh raw_matrix_generation.sh /mnt/gpfs/pt6/airflow/projects/2 /mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines

#task 14


#task 15
sh matrix_consolidation.sh /mnt/gpfs/pt6/airflow/projects/2 /mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines

#task qc
sh qc.sh /mnt/gpfs/pt6/airflow/projects/1 S1 /mnt/gpfs/pt2/Apps/CentOS7/FastQC-0.11.3

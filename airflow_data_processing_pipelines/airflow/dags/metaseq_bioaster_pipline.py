from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta
from airflow.operators import PythonOperator
from airflow.operators.subdag_operator import SubDagOperator
import shutil
import os
default_args = {
    'owner': 'biodata',
    'depends_on_past': False,
    'start_date': datetime(2017, 7, 1),
    'email': ['metaseq@bioaster.org'],
    'email_on_failure': True,
    'email_on_retry': True,
    'retries': 3,
    'retry_delay': timedelta(minutes=1),
}
dag = DAG('pengfei_pdu_test', default_args=default_args, schedule_interval=None, concurrency=512)
pipeline_bin_path = '/mnt/gpfs/pt6/airflow/bin'
project_directory = '/mnt/gpfs/pt6/airflow/projects/2'
sample_name_lists = ['S3', 'S4']
db_path = '/mnt/gpfs/pt2/Genomes/SILVA_db/SILVA123_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S.fasta'
dag_id = 'pengfei_pdu_test'
def output_result(project_directory, source_file_list):
    output_dir = project_directory+"/"+dag_id+"_results"
    for source_file in source_file_list:
        source_file_path = project_directory+"/tmp/QIIME_analysis/openref_vsearch_taxrdp_otus/"+source_file
        shutil.copy(source_file_path, output_dir)
def multiSampleConcatenation(project_directory, sample_name_lists):
    outputDirPath=project_directory+"/tmp/QIIME_analysis"
    outputFilePath=outputDirPath+"/seqs.fasta"
    if not os.path.exists(outputDirPath):
        os.makedirs(outputDirPath)
    if not sample_name_lists:
        print("Sample name List is empty")
    else:
        sampleLists = []
        for sampleName in sample_name_lists:
            samplePath = project_directory + "/tmp/preprocessing/" + sampleName + "_PEAR.assembled_trimmo_SGA.fasta"
            sampleLists.insert(0, samplePath)
        with open(outputFilePath, 'w') as outfile:
            for sample in sampleLists:
                with open(sample) as infile:
                    for line in infile:
                        outfile.write(line)
        print("Job done")
def sub_dag(parent_dag_name, child_dag_name, args, sampleNameList, startDate):
    dag_subdag = DAG(
        dag_id='%s.%s' % (parent_dag_name, child_dag_name),
        default_args=args,
        schedule_interval="@once",
        start_date=startDate-timedelta(minutes=2),
    )
    unzip_command = """
    find {{ params.project_dir }}/Rawdata -type f -name {{ params.sampleName }}'*.gz' | while IFS= read -r file; do
      gunzip "$file"
    done
    """
    assembly_op = """
    sh {{ params.pipeline_bin_path }}/assembly.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.pear_bin_path }}
    """
    trimming_trim_op = """
    sh {{ params.pipeline_bin_path }}/trimming_trimmomatic.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.trimming_bin_path }}
    """
    trimming_sga_op = """
    sh {{ params.pipeline_bin_path }}/trimming_sga.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.trim_sga_bin_path }}
    """
    fastq_to_fasta_op = """
    sh {{ params.pipeline_bin_path }}/fastq_to_fasta.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.fastq_to_fasta_bin_path }}
    """
    qc_op = """
    sh {{ params.pipeline_bin_path }}/qc.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.fastqc_bin_path }} {{ params.dag_id }}
    """
    for i in range(len(sampleNameList)):
        sampleName = sampleNameList[i]
        t1 = BashOperator(
            task_id='%s-unzip-%s' % (child_dag_name, sampleName),
            bash_command=unzip_command,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sampleName': sampleName},
            dag=dag_subdag)
        t2 = BashOperator(
            task_id='%s-Assembly_PEAR-%s' % (child_dag_name, sampleName),
            bash_command=assembly_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'pear_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/PEAR/bin'},
            dag=dag_subdag)
        t3 = BashOperator(
            task_id='%s-Trimming_Trimmomatic-%s' % (child_dag_name, sampleName),
            bash_command=trimming_trim_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'trimming_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/Trimmomatic-0.36'},
            dag=dag_subdag)
        t4 = BashOperator(
            task_id='%s-Trimming_SGA-%s' % (child_dag_name, sampleName),
            bash_command=trimming_sga_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'trim_sga_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/a5_miseq_linux_20150522/bin'},
            dag=dag_subdag)
        t5 = BashOperator(
            task_id='%s-Fastq_to_Fasta-%s' % (child_dag_name, sampleName),
            bash_command=fastq_to_fasta_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'fastq_to_fasta_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/ea-utils/clipper'},
            dag=dag_subdag)
        t6 = BashOperator(
            task_id='%s-QC-%s' % (child_dag_name, sampleName),
            bash_command=qc_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'dag_id': dag_id,
                    'sample_name': sampleName,
                    'fastqc_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/FastQC-0.11.3'},
            dag=dag_subdag)
        t2.set_upstream(t1)
        t3.set_upstream(t2)
        t4.set_upstream(t3)
        t5.set_upstream(t4)
        t6.set_upstream(t5)
    return dag_subdag

clean_up_op="""
rm -rf {{ params.project_dir }}/results/*
mkdir -p {{ params.project_dir }}/{{ params.dag_id }}_results
"""

clean_up = BashOperator(
    task_id='Clean_working_directory',
    bash_command=clean_up_op,
    params={'project_dir': project_directory,
            'dag_id': dag_id
            },
    dag=dag)

preprosessing = SubDagOperator(
   task_id='preprocess_sub_dag',
   subdag=sub_dag("pengfei_pdu_test", "preprocess_sub_dag", default_args, sample_name_lists, default_args['start_date']),
   dag=dag
)
ms_concatenation = PythonOperator(
        task_id='MultiSample_Concatenation',
        python_callable=multiSampleConcatenation,
        op_kwargs={'project_directory': project_directory,
                   'sample_name_lists': sample_name_lists
                   },
        dag=dag)
clustering_or_op = """
sh {{ params.pipeline_bin_path }}/clustering_or.sh {{ params.project_dir }} {{ params.qiime_co_bin_path }}
"""
clustering_or = BashOperator(
    task_id='Clustering_OpenReference',
    bash_command=clustering_or_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'qiime_co_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/Qiime',
            'db_path': db_path},
    queue='metaseq-clustering',
    dag=dag)
taxo_assignation_op = """
sh {{ params.pipeline_bin_path }}/taxo_assignation.sh {{ params.project_dir }} {{ params.rdp_bin_path }} {{ params.max_mem }}
"""
taxo_assignation = BashOperator(
    task_id='Taxo_Assignation',
    bash_command=taxo_assignation_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'rdp_bin_path' : '/mnt/gpfs/pt2/Apps/rdpclassifier-2.2-release',
            'max_mem': '3086'
            },
    dag=dag)
biom_generation_op = """
sh {{ params.pipeline_bin_path }}/biom_generation.sh {{ params.project_dir }}
"""
biom_generation = BashOperator(
    task_id='Biom_Generation',
    bash_command=biom_generation_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory},
    dag=dag)
tree_generation_op = """
sh {{ params.pipeline_bin_path }}/tree_generation.sh {{ params.project_dir }} {{ params.qiime_tree_bin_path }}
"""
tree_generation = BashOperator(
    task_id='Tree_Generation',
    bash_command=tree_generation_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'qiime_tree_bin_path': '/mnt/gpfs/pt2/Apps/CentOS7/Qiime'},
    dag=dag)
filter_weak_otus_op = """
sh {{ params.pipeline_bin_path }}/filter_weak_otus.sh {{ params.project_dir }}
"""
filter_weak_otus = BashOperator(
    task_id='Filter_weak_otus',
    bash_command=filter_weak_otus_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory},
    dag=dag)
biom_conversion_op = """
sh {{ params.pipeline_bin_path }}/biom_conversion.sh {{ params.project_dir }}
"""
biom_conversion = BashOperator(
    task_id='Biom_Conversion',
    bash_command=biom_conversion_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory},
    dag=dag)
raw_matrix_generation_op = """
sh {{ params.pipeline_bin_path }}/raw_matrix_generation.sh {{ params.project_dir }} {{ params.r_rawmatrix_bin_path}}
"""
raw_matrix_generation = BashOperator(
    task_id='Rawmatrix_generation',
    bash_command=raw_matrix_generation_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'r_rawmatrix_bin_path': '/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines'},
    dag=dag)
matrix_normalization_op = """
sh {{ params.pipeline_bin_path }}/matrix_normalization.sh {{ params.project_dir }} {{ params.r_matrix_norm_bin_path}}
"""
matrix_normalization = BashOperator(
    task_id='Matrix_Normalization',
    bash_command=matrix_normalization_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'r_matrix_norm_bin_path': '/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/'},
    dag=dag)
matrix_consolidation_op = """
sh {{ params.pipeline_bin_path }}/matrix_consolidation.sh {{ params.project_dir }} {{ params.pl_matrix_consolidation_bin_path}}
"""
matrix_consolidation = BashOperator(
    task_id='Matrix_Consolidation',
    bash_command=matrix_consolidation_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'pl_matrix_consolidation_bin_path': '/mnt/gpfs/pt2/Projets/Metagenomics/WP5-BIOINFORM/T5.2-targeted/src/metaseq-pipelines/'},
    dag=dag)
output_res = PythonOperator(
        task_id='Target',
        python_callable=output_result,
        op_kwargs={'project_directory': project_directory,
                   'source_file_list': ['Normalized_matrix.txt', 'Consolidated_matrix.txt', 'rep_set.tre', 'otu_table_filtered.biom', 'otu_table_filtered.biom.json']
                   },
        dag=dag)

deliver_res_op="""
cp -r {{ params.project_dir }}/{{ params.dag_id }}_results/* {{ params.project_dir }}/results
"""

deliver_res = BashOperator(
    task_id='Deliver_result',
    bash_command=deliver_res_op,
    params={
            'project_dir': project_directory,
            'dag_id':dag_id},
    dag=dag)

preprosessing.set_upstream(clean_up)
ms_concatenation.set_upstream(preprosessing)
clustering_or.set_upstream(ms_concatenation)
taxo_assignation.set_upstream(clustering_or)
biom_generation.set_upstream(clustering_or)
biom_generation.set_upstream(taxo_assignation)
tree_generation.set_upstream(clustering_or)
filter_weak_otus.set_upstream(biom_generation)
biom_conversion.set_upstream(filter_weak_otus)
raw_matrix_generation.set_upstream(biom_conversion)
matrix_normalization.set_upstream(raw_matrix_generation)
matrix_consolidation.set_upstream(matrix_normalization)
output_res.set_upstream(ms_concatenation)
output_res.set_upstream(tree_generation)
output_res.set_upstream(biom_conversion)
output_res.set_upstream(raw_matrix_generation)
output_res.set_upstream(matrix_consolidation)
deliver_res.set_upstream(output_res)

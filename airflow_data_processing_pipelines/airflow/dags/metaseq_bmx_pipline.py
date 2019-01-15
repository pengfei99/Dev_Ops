from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators import PythonOperator
from datetime import datetime, timedelta
from airflow.operators.subdag_operator import SubDagOperator
import shutil
import jinja2
import os

# Following are defaults which can be overridden later on
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

dag = DAG('pipeline_bmx', default_args=default_args, schedule_interval=None, concurrency=512)

# global static variable setup
pipeline_bin_path = '/mnt/gpfs/pt6/airflow/bin/bmx'

set_env_bin_path = '/mnt/gpfs/pt6/airflow/bin/bmx/package_metaseq/env-package.sh'

#don't forget to put the template there
conf_template_file_path = '/mnt/gpfs/pt6/airflow/bin/bmx/bmx_conf_file.j2'

bmx_conf_file_name = 'metag_pipeline_short16S.cfg'


# global dynamic variable to be replaced in the template
project_directory = '/mnt/gpfs/pt6/airflow/projects/4'

bmx_conf_file = project_directory + '/'+bmx_conf_file_name

sample_name_lists = ["S1", "S2", "S3"]

db_full_path = '/mnt/gpfs/pt6/airflow/bmx_pipeline_dependencies/singlerep/ApplDB_16S_V3-V5_Genus_clstr99_V3.2.fasta'

dag_id = 'pipeline_bmx'


def generate_conf_file():
    db_path, file_name = os.path.split(db_full_path)
    db_name = file_name[:-6]
    context = {
        'db_path': db_path,
        'db_name': db_name,
    }
    path, file_name = os.path.split(conf_template_file_path)
    result = jinja2.Environment(loader=jinja2.FileSystemLoader(path or './')).get_template(file_name).render(
        context)
    f = open(bmx_conf_file, 'w')
    f.write(result)
    f.close()


def generate_map_file():
    output_file = project_directory+"/sample_mapping_list.txt"
    with open(output_file, 'w') as f:
        for sample in sample_name_lists:
            content = project_directory+"/output/"+sample+"\t"+sample+"\n"
            f.write(content)
        f.close()


def get_result_with_dag_id():
    #creat two dir for result
    output_dir = project_directory+"/"+dag_id+"_results"
    output_qc_dir = output_dir+"/Summary"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if not os.path.exists(output_qc_dir):
        os.makedirs(output_qc_dir)
    normalized_matrix_source_file = project_directory+"/output/analysis/Data/row_matrix_normalized.metag"
    normalized_matrix_dest_file = output_dir+"/Normalized_matrix.txt"
    consolidated_matrix_source_file = project_directory+"/output/analysis/Data/global.metag.clean.matrixconsolidated"
    consolidated_matrix_dest_file = output_dir+"/Consolidated_matrix.txt"
    #copy and rename two matrix file
    shutil.copy(normalized_matrix_source_file, normalized_matrix_dest_file)
    shutil.copy(consolidated_matrix_source_file,consolidated_matrix_dest_file)
    #copy and rename sample fast qc file  S4.txt
    for sample in sample_name_lists:
        full_sample_name = sample+"_L001_R1_001.merged_fastqc"
        sample_qc_source_file = project_directory+"/output/"+sample+"/FastQC/"+full_sample_name+"/summary.txt"
        sample_qc_dest_file = output_qc_dir+"/"+sample+".txt"
        shutil.copy(sample_qc_source_file, sample_qc_dest_file)


def sub_dag(parent_dag_name, child_dag_name, args, startDate):

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

    preprosessing_op = """
    sh {{ params.pipeline_bin_path }}/preprocessing_op.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.bmx_conf_file }} {{ params.set_env_bin_path }}
    """

    merging_paired_reads_op = """
    sh {{ params.pipeline_bin_path }}/merging_paired_reads_op.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.bmx_conf_file }} {{ params.set_env_bin_path }}
    """

    mapping_seq_to_db = """
    sh {{ params.pipeline_bin_path }}/mapping_seq_to_db.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.bmx_conf_file }} {{ params.set_env_bin_path }}
    """

    merge_bam_file_op = """
    sh {{ params.pipeline_bin_path }}/merge_bam_file_op.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.bmx_conf_file }} {{ params.set_env_bin_path }}
    """

    taxo_assignment_op = """
    sh {{ params.pipeline_bin_path }}/taxo_assignment_op.sh {{ params.project_dir }} {{ params.sample_name }} {{ params.bmx_conf_file }} {{ params.set_env_bin_path }}
    """

    for i in range(len(sample_name_lists)):
        sampleName = sample_name_lists[i]

        t1 = BashOperator(
            task_id='%s-unzip-%s' % (child_dag_name, sampleName),
            bash_command=unzip_command,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sampleName': sampleName,
                    },
            dag=dag_subdag)

        t2 = BashOperator(
            task_id='%s-preprocessing-%s' % (child_dag_name, sampleName),
            bash_command=preprosessing_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'bmx_conf_file': bmx_conf_file,
                    'set_env_bin_path': set_env_bin_path
                    },
            dag=dag_subdag)

        t3 = BashOperator(
            task_id='%s-merging_paired_reads-%s' % (child_dag_name, sampleName),
            bash_command=merging_paired_reads_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'bmx_conf_file': bmx_conf_file,
                    'set_env_bin_path': set_env_bin_path
                    },
            dag=dag_subdag)

        t4 = BashOperator(
            task_id='%s-mapping_seq_to_db-%s' % (child_dag_name, sampleName),
            bash_command=mapping_seq_to_db,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'bmx_conf_file': bmx_conf_file,
                    'set_env_bin_path': set_env_bin_path
                    },
            dag=dag_subdag)

        # task 6 quality control
        t5 = BashOperator(
            task_id='%s-Merge_Bam_file-%s' % (child_dag_name, sampleName),
            bash_command=merge_bam_file_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'bmx_conf_file': bmx_conf_file,
                    'set_env_bin_path': set_env_bin_path
                    },
            dag=dag_subdag)

        t6 = BashOperator(
            task_id='%s-Taxonomic_assignment-%s' % (child_dag_name, sampleName),
            bash_command=taxo_assignment_op,
            params={'pipeline_bin_path': pipeline_bin_path,
                    'project_dir': project_directory,
                    'sample_name': sampleName,
                    'bmx_conf_file': bmx_conf_file,
                    'set_env_bin_path': set_env_bin_path
                    },
            dag=dag_subdag)

        t2.set_upstream(t1)
        t3.set_upstream(t2)
        t4.set_upstream(t3)
        t5.set_upstream(t4)
        t6.set_upstream(t5)

    return dag_subdag

clean_project_dir_op = """
rm -rf {{ params.project_dir }}/output/*
"""

# task 0 clean working directory
clean_project_dir = BashOperator(
    task_id='clean_project_dir',
    bash_command=clean_project_dir_op,
    params={'project_dir': project_directory,
            },
    dag=dag)


# task 1 generate conf for this run
generate_conf = PythonOperator(
    task_id='generate_conf',
    python_callable=generate_conf_file,
    dag=dag
        )

# task 2 preprosess all samples
preprosessing = SubDagOperator(
    task_id='preprocess_sub_dag',
    provide_context=True,
    subdag=sub_dag("pipeline_bmx", "preprocess_sub_dag", default_args, default_args['start_date']),
    dag=dag
)

# task 2-1 generate sample file
generate_sample_mapping_file = PythonOperator(
    task_id='generate_sample_mapping_file',
    python_callable=generate_map_file,
    dag=dag
        )

#task 3
mgx_metagenomic_analyses_op = """
sh {{ params.pipeline_bin_path }}/metagenomic_analyses_op.sh {{ params.project_dir }} {{ params.set_env_bin_path }}
"""

mgx_metagenomic_analyses = BashOperator(
    task_id='Mgx_Metagenomic_Analyses',
    bash_command=mgx_metagenomic_analyses_op,
    params={'pipeline_bin_path': pipeline_bin_path,
            'project_dir': project_directory,
            'set_env_bin_path': set_env_bin_path
            },
    queue='metaseq-clustering',
    dag=dag)


#task 4 get result in result-dag-id folder
get_result = PythonOperator(
    task_id='get_result',
    python_callable=get_result_with_dag_id,
    dag=dag
    )

deliver_res_op="""
mkdir -p {{ params.project_dir }}/results
cp -r {{ params.project_dir }}/{{ params.dag_id }}_results/* {{ params.project_dir }}/results
"""

deliver_res = BashOperator(
    task_id='Deliver_result',
    bash_command=deliver_res_op,
    params={
            'project_dir': project_directory,
            'dag_id':dag_id},
    dag=dag)

# pipline for preprosessing one sample
generate_conf.set_upstream(clean_project_dir)
preprosessing.set_upstream(generate_conf)
generate_sample_mapping_file.set_upstream(generate_conf)
mgx_metagenomic_analyses.set_upstream(generate_sample_mapping_file)
mgx_metagenomic_analyses.set_upstream(preprosessing)
get_result.set_upstream(mgx_metagenomic_analyses)
deliver_res.set_upstream(get_result)

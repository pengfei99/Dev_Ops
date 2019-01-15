import json


def set_dag_params(params, project_directory):
    conf_file_path = project_directory+'/dag_params.json'
    # Writing JSON data
    with open(conf_file_path, 'w') as f:
        json.dump(params, f)


def get_dag_params(project_directory):
    conf_file_path = project_directory + '/dag_params.json'
    with open(conf_file_path, 'r') as f:
        data = json.load(f)

    sample_name_lists = data['sample_name_lists']
    print(data['pipeline_bin_path'])
    print(data['project_directory'])
    print(sample_name_lists)
    for sample in sample_name_lists:
        print(sample)
    print(data['db_path'])



params = {
    'pipeline_bin_path': '/mnt/gpfs/pt6/airflow/bin',
    'project_directory': '/mnt/gpfs/pt6/airflow/projects/1',
    'sample_name_lists': ["S3", "S4"],
    'db_path': '/mnt/gpfs/pt2/Genomes/SILVA_db/SILVA123_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S_withoutUncultured_84425.fasta'
    }
conf_file_path = '/tmp'

set_dag_params(params, conf_file_path)
get_dag_params(conf_file_path)

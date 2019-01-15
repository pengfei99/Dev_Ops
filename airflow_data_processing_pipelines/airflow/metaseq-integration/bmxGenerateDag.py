import os
import jinja2
import time

def populate_template(file_path, context):
    path, file_name = os.path.split(file_path)
    return jinja2.Environment(loader=jinja2.FileSystemLoader(path or './')).get_template(file_name).render(context)


def generate_dag_file(dag_id, project_directory, sample_ids, db_path):
    #need to be modified
    template_path = '/home/pliu/PycharmProjects/Tutorial'
    template_file_path = template_path+'/bmx_dag_template.j2'
    dag_bag_path = '/home/pliu/airflow/dags'
    dag_file_path = dag_bag_path+'/pipeline_bioaster_'+dag_id+".py"
    context = {
        'dag_id': dag_id,
        'project_directory': project_directory,
        'sample_ids': sample_ids,
        'db_path': db_path,
    }
    result = populate_template(template_file_path, context)
    f = open(dag_file_path, 'w')
    f.write(result)
    f.close()
    time.sleep(15)


generate_dag_file('bmx-generate-text', '/mnt/gpfs/pt6/airflow/projects/4', ["S3","S4","S1","S2"], 'ApplDB_16S_V3-V5_Genus_clstr99_V3.2' )

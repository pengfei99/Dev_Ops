
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'biodata',
    'depends_on_past': False,
    'start_date': datetime.now()-timedelta(minutes=120),
    'email': ['metaseq@bioaster.org'],
    'email_on_failure': True,
    'email_on_retry': True,
    'retries': 3,
    'retry_delay': timedelta(minutes=1),
}

dag = DAG(
    'pipeline-metaseq', default_args=default_args, schedule_interval=None, concurrency=100)


templated_command = """
sleep 15 
date >> /mnt/gpfs/pt6/pveyre/dag-result.txt
echo {{ dag_run.conf['project_directory'] }} >> /mnt/gpfs/pt6/pveyre/dag-result.txt
echo --------------- >> /mnt/gpfs/pt6/pveyre/dag-result.txt
"""


t1 = BashOperator(
    task_id='sleep_1',
    bash_command=templated_command,
    dag=dag)

t2 = BashOperator(
    task_id='sleep_2',
    bash_command=templated_command,
    dag=dag)

t3 = BashOperator(
    task_id='sleep_3',
    bash_command=templated_command,
    dag=dag)

t4 = BashOperator(
    task_id='sleep_4',
    bash_command=templated_command,
    dag=dag)

t5 = BashOperator(
    task_id='sleep_5',
    bash_command=templated_command,    
    dag=dag)

t2.set_upstream(t1)
t3.set_upstream(t1)
t4.set_upstream(t3)
t5.set_upstream(t4)



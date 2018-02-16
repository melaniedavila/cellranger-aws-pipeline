import boto3
import glob
import json

client_cf = boto3.client('cloudformation')
client_batch = boto3.client('batch')

stack_name = 'cellranger-job'

# Get stack info from cloudformation
##############################################
stack_info = client_cf.describe_stack_resources(StackName=stack_name)
resources = stack_info['StackResources']

for inst_resource in resources:
  resource_type = inst_resource['ResourceType']
  logical_resource_id = inst_resource['LogicalResourceId']

  # job 1
  if logical_resource_id == 'JobDef1':
    job_def_id_1 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  # job 2
  if logical_resource_id == 'JobDef2':
    job_def_id_2 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  # job 3
  if logical_resource_id == 'JobDef3':
    job_def_id_3 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  # job 4
  if logical_resource_id == 'JobDef4':
    job_def_id_4 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  # job 5
  if logical_resource_id == 'JobDef5':
    job_def_id_5 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  # job 6
  if logical_resource_id == 'JobDef6':
    job_def_id_6 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  if resource_type == 'AWS::Batch::JobQueue':
    job_queue_id = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]


# single-sample-job initialization
####################################
base_name = 'cellranger-OPTIMAL-6part'
params_dict = {}
params_dict['bucket'] = 'cellranger_bucket'

# job 1
#########################
batch_job_name = base_name + '-10GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_1,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)

# job 2
#######################
batch_job_name = base_name + '-15GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_2,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)


# job 3
#######################
batch_job_name = base_name + '-20GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_3,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)

# job 4
#######################
batch_job_name = base_name + '-25GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_4,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)

# job 5
#######################
batch_job_name = base_name + '-30GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_5,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)

# job 6
#######################
batch_job_name = base_name + '-64GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_6,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)


job_id_1 = job_response['jobId']
print('submitted job 1: ' + batch_job_name)

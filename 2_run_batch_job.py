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

  if resource_type == 'AWS::Batch::JobQueue':
    job_queue_id = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]


# single-sample-job initialization
####################################
base_name = 'cellranger-m54xlarge'
params_dict = {}
params_dict['bucket'] = 'cellranger_bucket'

# mounted volume 5GB RAM
#########################
batch_job_name = base_name + '-mounted-volume-5GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_1,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)

# mounted volume 10GB
#######################
batch_job_name = base_name + '-mounted-volume-10GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_2,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)


# mounted volume 30GB
#######################
batch_job_name = base_name + '-mounted-volume-30GB'
job_response = client_batch.submit_job(jobDefinition=job_def_id_3,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id)

# # mounted volume 64GB
# #######################
# batch_job_name = base_name + '-mounted-volume-64GB'
# job_response = client_batch.submit_job(jobDefinition=job_def_id_4,
#                                        jobName=batch_job_name,
#                                        jobQueue=job_queue_id)


job_id_1 = job_response['jobId']
print('submitted job 1: ' + batch_job_name)

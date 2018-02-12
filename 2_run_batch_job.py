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

  # 1 single job
  if logical_resource_id == 'JobDef1':
    job_def_id_1 = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]

  if resource_type == 'AWS::Batch::JobQueue':
    job_queue_id = inst_resource['PhysicalResourceId'].split('/')[-1].split(':')[0]


# single-sample-job initialization
####################################
base_name = 'cellranger-1'
params_dict = {}
params_dict['bucket'] = 'cellranger_bucket'


# single-sample-job 1
######################
batch_job_name = base_name + '-single-1'
params_dict['inst_fcs'] = 'something'
parameters={'inst_argument': json.dumps(params_dict)}
job_response = client_batch.submit_job(jobDefinition=job_def_id_1,
                                       jobName=batch_job_name,
                                       jobQueue=job_queue_id,
                                       parameters=parameters)

job_id_1 = job_response['jobId']
print('submitted job 1: ' + batch_job_name)

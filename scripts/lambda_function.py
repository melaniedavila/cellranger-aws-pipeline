import boto3
import datetime as dt
import json

AWS_ECR_REGISTRY = '402084680610.dkr.ecr.us-east-1.amazonaws.com'

PIPELINE_NAME = 'test-cellranger-pipeline'
JOB_QUEUE = PIPELINE_NAME # TODO: verify that this name is correct
ANALYSIS_JOB_NAME = f'{PIPELINE_NAME}-analysis'
MKFASTQ_JOB_NAME = f'{PIPELINE_NAME}-mkfastq'

batch_client = boto3.client('batch')

def experiment_name(run, himc_pool, sequencing_date):
    sequencing_date_object = dt.datetime.strptime(sequencing_date, "%Y-%m-%d").date()
    return f'run{run}-himc{himc_pool}-{sequencing_date_object.strftime(""%m%d%y")}'

def submit_analysis(sample, experiment, image_name, depends_on = []):
    job_configuration = {
        "experiment_name": experiment_name(experiment),
        "sample": sample
    }
    parameters = {
        "image_name": image_name
        "configuration": json.dumps(job_configuration)
    }

    try:
        response = batch_client.submit_job(
            dependsOn=depends_on,
            jobDefinition=job_definition,
            jobName=ANALYSIS_JOB_NAME,
            jobQueue=JOB_QUEUE,
            parameters=parameters
        )
        # Log response from AWS Batch
        print("debug: " + json.dumps(response, indent=2))
        return response['jobId']
    except Exception as e:
        print(e)
        message = 'Error submitting Batch Job'
        print(message)
        raise Exception(message)

def submit_mkfastq(samples, experiment, image_name):
    job_configuration = {
        "experiment_name": experiment_name(experiment),
        "run_id": experiment["run_id"],
        "samples": samples
    }
    parameters = {
        "image_name": image_name,
        "configuration": json.dumps(job_configuration)
    }

    try:
        response = batch_client.submit_job(
            jobDefinition=job_definition,
            jobName=ANALYSIS_JOB_NAME,
            jobQueue=JOB_QUEUE,
            parameters=parameters
        )
        # Log response from AWS Batch
        print("debug: " + json.dumps(response, indent=2))
        return response['jobId']
    except Exception as e:
        print(e)
        message = 'Error getting Batch Job status'
        print(message)
        raise Exception(message)

def lambda_handler(event, context):
    configuration = event['configuration']

    bcl2fastq_version = configuration['experiment']['bcl2fastq_version']
    cellranger_version = configuration['experiment']['cellranger_version']
    image_name = f'{AWS_ECR_REGISTRY}/cellranger-{cellranger_version}-bcl2fastq-{bcl2fastq_version}'

    processing = configuration['processing']
    processing_job_ids = []

    if processing['mkfastq']:
        print(f'info: processing: mkfastq: submitting: {sample["name"]}')
        mkfastq_job_id = submit_mkfastq(processing['mkfastq'],
                                        experiment=experiment,
                                        image_name=image_name)
        processing_job_ids.append(mkfastq_job_id)
        print(f'info: processing: mkfastq: submitted: {sample["name"]}')

    if configuration['analyses']:
        for sample in configuration['analyses']['samples']:
            print(f'info: analyses: submitting: {sample["name"]}')
            submit_analysis(sample,
                            experiment=experiment,
                            image_name=image_name,
                            depends_on=processing_job_ids)
            print(f'info: analyses: submitted: {sample["name"]}')

    print("info: all jobs submitted successfully.")

    return {
        'statusCode': 200,
        'body': {}
    }

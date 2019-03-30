#!/usr/bin/env python3.6

import boto3
import datetime as dt
import json
import sys

AWS_ECR_REGISTRY = '402084680610.dkr.ecr.us-east-1.amazonaws.com'

PIPELINE_NAME = 'test-cellranger-pipeline'
JOB_QUEUE = 'test-10xpipeline'
JOB_NAME = f'{PIPELINE_NAME}-mkfastq' # TODO: remove mkfastq from job name

batch_client = boto3.client('batch')

def generate_experiment_name(run, himc_pool, sequencing_date, **_):
    sequencing_date_object = dt.datetime.strptime(sequencing_date, "%Y-%m-%d").date()
    return f'run{run}-himc{himc_pool}-{sequencing_date_object.strftime("%m%d%y")}'

def submit_analysis(sample, experiment, depends_on = []):
    experiment_name = generate_experiment_name(**experiment)
    job_configuration = {
        "experiment_name": experiment_name,
        "sample": sample
    }
    parameters = {
        "command": "analysis",
        "configuration": json.dumps(job_configuration)
    }

    print()
    print()
    print(depends_on)
    print()
    print()
    try:
        response = batch_client.submit_job(
            dependsOn=depends_on,
            jobDefinition=f'{JOB_NAME}',
            jobName=f'{JOB_NAME}-{experiment_name}-{sample["job_type"]}-{sample["job_name"]}',
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

def submit_mkfastq(samples, experiment):
    experiment_name = generate_experiment_name(**experiment)
    job_configuration = {
        "experiment_name": experiment_name,
        "run": experiment["run"],
        "samples": samples
    }
    parameters = {
        "command": "mkfastq",
        "configuration": json.dumps(job_configuration)
    }

    try:
        response = batch_client.submit_job(
            jobDefinition=f'{JOB_NAME}',
            jobName=f'{JOB_NAME}-{experiment_name}-mkfastq',
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
    experiment = configuration['experiment']
    bcl2fastq_version = experiment['bcl2fastq_version']
    cellranger_version = experiment['cellranger_version']

    processing = configuration['processing']
    processing_job_ids = []

    if processing['mkfastq']:
        print(f'info: processing: mkfastq: submitting')
        mkfastq_job_id = submit_mkfastq(processing['mkfastq'],
                                        experiment=experiment)
        processing_job_ids.append(mkfastq_job_id)
        print(f'info: processing: mkfastq: submitted')

    if configuration['analyses']:
        for sample in configuration['analyses']['samples']:
            print(f'info: analyses: submitting: {sample["name"]}')
            # submit_analysis(sample,
            #                 experiment=experiment,
            #                 depends_on= [ {"jobId": job_id} for job_id in processing_job_ids ])
            print('FIXME: PRETENDING TO SUBMIT')
            print(f'info: analyses: submitted: {sample["name"]}')

    print("info: all jobs submitted successfully.")

    return {
        'statusCode': 200,
        'body': {}
    }

if __name__ == "__main__":
    event = json.load(sys.stdin)
    lambda_handler(event, None)

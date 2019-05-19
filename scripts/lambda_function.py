#!/usr/bin/env python3.6

# This script submits experiment jobs to AWS Batch. It may be run
# either locally or on AWS Lambda.

import boto3
import datetime as dt
import json
import sys

AWS_ECR_REGISTRY = '402084680610.dkr.ecr.us-east-1.amazonaws.com'

PIPELINE_NAME = 'test-cellranger-pipeline'
JOB_QUEUE = 'test-10xpipeline'
JOB_NAME = f'{PIPELINE_NAME}-mkfastq' # TODO: remove mkfastq from job name
SEQUENCING_RUN_NAME_DELIMITER="-"
SEQUENCING_RUN_FIELD_DELIMITER="_"

batch_client = boto3.client('batch')

def generate_sequencing_run_name(sequencing_run):
    run_id=sequencing_run['id']
    himc_pool=sequencing_run['himc_pool']
    sequencing_date=sequencing_run['date']
    sequencing_date_object = dt.datetime.strptime(sequencing_date, "%Y-%m-%d").date()
    sequencing_run_fields=[f'run{run_id}',
                           f'himc{himc_pool}',
                           sequencing_date_object.strftime("%m%d%y")]
    return SEQUENCING_RUN_FIELD_DELIMITER.join(sequencing_run_fields)

def generate_experiment_name(sequencing_runs, **_):
    sequencing_run_names=map(generate_sequencing_run_name, sequencing_runs)
    return SEQUENCING_RUN_NAME_DELIMITER.join(sequencing_run_names)

def submit_analysis(sample, experiment, depends_on = []):
    experiment_name = generate_experiment_name(**experiment)
    container_overrides = {
        "environment": [
            {
                "name": "DEBUG",
                "value": str(experiment.get('meta', {}).get('debug', False) is True).lower()
            }
        ]
    }
    job_configuration = {
        "experiment_name": experiment_name,
        "run": experiment["run"],
        "sample": sample
    }
    parameters = {
        "command": "analysis",
        "configuration": json.dumps(job_configuration)
    }

    try:
        response = batch_client.submit_job(
            containerOverrides=container_overrides,
            dependsOn=depends_on,
            jobDefinition=f'{JOB_NAME}',
            jobName=f'{JOB_NAME}-{experiment_name}-{sample["job_type"]}-{sample["name"]}',
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

def submit_mkfastq(bcl_file, experiment, run_id, samples):
    experiment_name = generate_experiment_name(**experiment)
    container_overrides = {
        "environment": [
            {
                "name": "DEBUG",
                "value": str(experiment.get('meta', {}).get('debug', False) is True).lower()
            }
        ]
    }
    job_configuration = {
        "bcl_file": bcl_file,
        "experiment_name": experiment_name,
        "run_id": run_id,
        "samples": samples
    }
    parameters = {
        "command": "mkfastq",
        "configuration": json.dumps(job_configuration)
    }

    try:
        response = batch_client.submit_job(
            containerOverrides=container_overrides,
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
        samples=processing['mkfastq']['samples']
        for bcl_file, run_id in [[sequencing_run['bcl_file'], sequencing_run['id']] for sequencing_run in experiment['sequencing_runs']]:
            print(f'info: processing: mkfastq: submitting: {bcl_file}')
            mkfastq_job_id = submit_mkfastq(bcl_file=bcl_file,
                                            experiment=experiment,
                                            run_id=run_id,
                                            samples=samples)
            processing_job_ids.append(mkfastq_job_id)
            print(f'info: processing: mkfastq: submitted: {bcl_file}')

    if configuration['analyses']:
        for sample in configuration['analyses']['samples']:
            print(f'info: analyses: submitting: {sample["name"]}')
            submit_analysis(sample,
                            experiment=experiment,
                            depends_on=[ {"jobId": job_id} for job_id in processing_job_ids ])
            print(f'info: analyses: submitted: {sample["name"]}')

    print("info: all jobs submitted successfully.")

    return {
        'statusCode': 200,
        'body': {}
    }

if __name__ == "__main__":
    event = json.load(sys.stdin)
    lambda_handler(event, None)

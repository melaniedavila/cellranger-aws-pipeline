# Proposed Workflow

1. Run `./submit /path/to/cellranger-pipeline-config.yaml`
    a. The `./submit` script then:
        i. Converts the `cellranger-pipeline-config.yaml` to JSON,
           because JSON is more easily serialized as a string.
        ii. `aws lambda invoke`s the cellranger pipeline entrypoint (name TBD) with that JSON string.
    b. The cellranger pipeline entrypoint AWS Lambda function then:
        i. Validates the pipeline config JSON and raises an error if it's invalid
        ii. Uploads the config (as yaml) to S3 (somewhere in `s3://10x-pipeline/`)
        iii. Submits the various AWS Batch Jobs that comprise the cellranger pipeline.
2. The user submitting the pipeline config then checks AWS Batch for logs.
3. The user submitting the pipeline config then check back 36 hours later for final results.
    a. TODO: Notify the user, someday.

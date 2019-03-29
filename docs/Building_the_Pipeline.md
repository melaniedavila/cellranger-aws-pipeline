# Steps Taken to Build Pipeline
This document provides a high-level walkthrough of how the pipeline was built.
1. Create `Makefile` to enable shorter Docker-related commands in the future.
We anticipate using the git commit sha in order to identify the source of different
versions of our `Dockerfile`.
2. Make Dockerfile with build args
3. Build Docker image via make command
4. Make ECR repo
5. Push image to ECR repo
6. Create AMI with 1TB storage
7. Create IAM role `cellranger-pipeline`
	- Attach 2 IAM policies
		- one policy to read and write to 10x-data-backup (s3-10x-data-backup-read-write)
		- one policy to read to 10x-pipeline (s3-10x-pipeline-read)
8. Create Batch resource; compute environment
9. Create Batch job definition: cellranger-pipeline-mkfastq
10. Write submit script to invoke lambda function and pass it yaml config contents
11. Create lambda function via AWS GUI
	- Write `lambda_function.py` script to be executed by lambda function
	- Create json schema to validate yaml config file
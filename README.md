# Cellranger AWS Pipeline

  This repo is working towards deploying the 10X cellranger pipeline on AWS. In a separate repo, [dockerized-cellranger](https://github.com/ismms-himc/dockerized_cellranger), we ran `cellranger mkfastq` and `cellranger count` in a docker container using the `tiny-bcl` example dataset (the image ran successfully on linux but not on mac). However, the reference transcriptome (e.g. GRCh38) was included in the docker iamge, which made the image ~18GB and this is too large to run on AWS batch. We are working on a docker image that uses `boto` to copy the reference from S3 to a 1TB mounted volume (see `docker_scratch` below).

  Currently, we can get several jobs to run and share the same `docker_scratch` directory and have access to up to 64GB of memory. Next, we are working on getting jobs to run `cellranger mkfastq` and `cellranger count`.

  ## Pipeline Overview
  * step-1: Download bcl data and reference transcriptome from S3
  * step-2: Run single `cellranger mkfastq` job on tiny-bcl data
  * step-3: Run multiple `cellranger count` jobs on the tiny-bcl fastqs (use samplesheet)

  ### To Do

  * get jobs to write to different directories within the 1TB `docker_scratch` directory
  * set up AMI that can be ssh'd into

  * ~~run cellranger mkfastq and count on tiny-bcl as AWS batch job~~
  * ~~save cellranger outputs back to S3 bucket~~
  * ~~set up python script to actually run the cellranger commands~~
  * ~~test running jobs with higher memory requirements, we need about 30-60GB~~

The steps required to submit jobs to AWS batch are discussed below.

# 1. Build Stack using Cloudformation and Make AMI with 1TB Volume

  The following commands can be used to create and update the stack on AWS using the `cf_cellranger.json` cloudformation

  `$ aws cloudformation create-stack --template-body file://cf_cellranger.json --stack-name cellranger-job --capabilities CAPABILITY_NAMED_IAM`

  `$ aws cloudformation update-stack --template-body file://cf_cellranger.json --stack-name cellranger-job --capabilities CAPABILITY_NAMED_IAM`

  The cloudformation template sets up the mounted volume for the jobs (see jobdefinition in template) and tells batch to use a custom AMI that has a mounted 1TB volume for the compute environment. See [aws-batch-genomics](https://aws.amazon.com/blogs/compute/building-high-throughput-genomic-batch-workflows-on-aws-batch-layer-part-3-of-4/) part 3 to see how to make a custom AMI. Also see the [cloudformation docs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-batch-computeenvironment.html) for an exmaple of how to use a custom AMI as a compute environment for AWS batch. Additional helpful links:
    * [aws London pop-up video batch computing](https://www.youtube.com/watch?v=H8bmHU_z8Ac&t=662s)
    * [base2 genomics presentation for AWS re:invent](https://www.youtube.com/watch?v=8dApnlJLY54&t=2785s)

# 2. Upload reference data to S3

  Upload `refdata-cellranger-GRCh38-1.2.0` to S3 (~16GB) using `common_utils`. This reference is not in the repo and the upload was done elsewhere.


# 3. Make and Run Docker Image that will be used as the Batch Job Definition
  Use the following docker commands to build and run the container. See the next section for the commands to run within the contianer.

  `$ docker build -t <URI>.dkr.ecr.us-east-1.amazonaws.com/awsbatch/cellranger-aws-pipeline .`

  `$ docker run -it --rm -p 8087:80 <URI>.dkr.ecr.us-east-1.amazonaws.com/awsbatch/cellranger-aws-pipeline`

# 4. Push Image to AWS ECS

  After the image has been built it needs to be pushed to AWS ECS. First auth credentials need to be obtained by running

  `$ aws ecr get-login`

  This will return a long aws CLI command that you need to copy and paste into the terminal. You may need to remove `-e none` from the command if docker gives an error. Now that you have the proper credentials, you will be able to push the repository using the following command:

  `$ docker push <URI>.dkr.ecr.us-east-1.amazonaws.com/awsbatch/cellranger-aws-pipeline`

# 5. Create AMI
While in the AWS console, go to the EC2 service section. Click "Instances" on the
left-hand side panel. Then hit the blue "Launch" button near the top of the page.
This will take you to Amazon Marketplace.

- Step 1 (choose AMI): select "Amazon ECS-Optimized Amazon Linux AMI".
- Step 2 (choose an instance type): select t2.micro
- Step 3 (skip)
- Step 4 (add storage): Two entries must be made as per [this AWS tutorial](https://aws.amazon.com/blogs/compute/building-high-throughput-genomic-batch-workflows-on-aws-batch-layer-part-3-of-4/)
Follow the screenshot they provide.
- Final Step (only steps 1, 2, and 4 needed prior to this): Click "Review and 
Launch" and then "Launch". You will be prompted to select an existing key pair 
or create a new pair. 
    - If creating a new key pair, ensure to save the pem file 
    for future use and run `chmod 400` on the pem file. You can then
    hit "Launch Instance" and ssh into your instance.

Again, in the EC2 service section, click "Instances" on the left-hand side panel.
You should now see the instance you created in the last step. Select the instance,
click "Actions" (near the blue "Launch Instance" button), hover over "Image", click
"Create Image". Fill in the "Image name" field and click the "Create Image" button.

Ensure to replace the AMI ID fields in the `cf_cellranger.json` file with the ID of the 
AMI you just created. To find the AMI ID, in the EC2 service section, under "Images"
on the left-hand side panel, click "AMIs", and copy the AMI ID corresponding to 
the AMI you just created.

Reminder: Don't forget to update the stack via the following command:
`$ aws cloudformation update-stack --template-body file://cf_cellranger.json --stack-name cellranger-job --capabilities CAPABILITY_NAMED_IAM`

# 6. Run Cellranger Commands in Container (in-progress)

  These Cellranger commands can be run after changing directories to the `scratch` directory. They will be run by `run_cellranger_pipeline.py`, which currently only copies the reference genome from S3.

  ### Cellranger mkfastq
  `$ cellranger mkfastq --id=tiny-bcl-output --run=tiny-bcl/cellranger-tiny-bcl-1.2.0/ --csv=tiny-bcl/cellranger-tiny-bcl-samplesheet-1.2.0.csv`

  ### Cellranger count
  `$ cellranger count --id=test_sample --fastqs=tiny-bcl-output/outs/fastq_path/p1/s1 --sample=test_sample --expect-cells=1000 --localmem=3 --chemistry=SC3Pv2 --transcriptome=refdata-cellranger/refdata-cellranger-GRCh38-1.2.0`

Note: The samplesheet 10X provides for the tiny-bcl example is more complex than
the samplesheets we provide during our own runs of the cellranger pipeline. As of
02/22/18, we create these sample sheet csv files manually on the command line using
data from Laura's "10x Chromium scRNA-Seq" google sheet ("Sequencing Prep & QC" 
tab) under the ismmshimc@gmail.com gmail account. We plan to automate this task
along with various others (i.e. filling out the `cellranger count` parameter 
`expect-cells` ) once the AWS pipeline is streamlined. The sample sheet 
should look like the below example:

```
[Data]
Lane,Sample_ID,Sample_Name,index
,SI-GA-B6,MC68NN1,SI-GA-B6
,SI-GA-B7,MC68NN2,SI-GA-B7
,SI-GA-B8,MC68TN1,SI-GA-B8

```
To date (02/22/18), the following has been true of the sample sheets:
  - The `Lane` column is empty
  - `Sample_ID` and `Index` columns have the same value and are always prefixed
  with `SI-GA-`

# System Requirements (from [10X Genomics](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/system-requirements))

System Requirements
Cell Ranger
Cell Ranger pipelines run on Linux systems that meet these minimum requirements:

8-core Intel or AMD processor (16 recommended)
64GB RAM (128GB recommended)
1TB free disk space
64-bit CentOS/RedHat 5.5 or Ubuntu 10.04
The pipelines also run on clusters that meet these minimum requirements:

8-core Intel or AMD processor per node
6GB RAM per core
Shared filesystem (e.g. NFS)
SGE or LSF
In addition, Cell Ranger must be run on a system with the following software pre-installed:

Illumina bcl2fastq
bcl2fastq 2.17 or higher is preferred and supports most sequencers running RTA version 1.18.54 or higher. If you are using a NovaSeq, please use version 2.20 or higher. If your sequencer is running an older version of RTA, then bcl2fastq 1.8.4 is required by Illumina.

All other software dependencies come bundled in the Cell Ranger package.

# Components

Modified from from dockerfile: https://hub.docker.com/r/litd/docker-cellranger/

10X Genomics Cell Ranger Suite

bcl2fastq2 v2.19 (06/13/2017)

cellranger v2.1.0

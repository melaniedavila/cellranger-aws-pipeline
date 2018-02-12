# Dockerfile Overview
Modified from from dockerfile: https://hub.docker.com/r/litd/docker-cellranger/

10X Genomics Cell Ranger Suite

CentOS 7

bcl2fastq2 v2.19 (06/13/2017)

cellranger v2.1.0

# Make Docker Image and Run Container
  Use the following docker commands to build and run the container. See the next section for the commands to run within the contianer.

  `$ docker build -t docker-cellranger .`

  `$ docker run -it --rm -p 8087:80 docker-cellranger`

# Commands to run within a running docker container

  ### Cellranger mkfastq
  `$ cellranger mkfastq --id=tiny-bcl-output --run=/tiny-bcl/cellranger-tiny-bcl-1.2.0/ --csv=/tiny-bcl/cellranger-tiny-bcl-samplesheet-1.2.0.csv`

  See mkfastq_output.txt for output

  ### Cellranger count
  `$ cellranger count --id=test_sample --fastqs=/tiny-bcl-output/outs/fastq_path/p1/s1 --sample=test_sample --expect-cells=1000 --transcriptome=/refdata-cellranger-GRCh38-1.2.0`

  See count_output.txt for output.

# Output from cellranger commands

See mkfastq_output.txt for the terminal output.

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

# Migrating to AWS

519400500372.dkr.ecr.us-east-1.amazonaws.com/awsbatch/cellranger-aws-pipeline
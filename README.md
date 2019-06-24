# Cellranger AWS Pipeline

We deploy the 10X Genomics [cellranger
pipeline](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/what-is-cell-ranger)
on AWS. This pipeline builds upon previous work done by Nick
(following the AWS batch genomics
[example](https://aws.amazon.com/blogs/compute/building-high-throughput-genomics-batch-workflows-on-aws-introduction-part-1-of-4/)
and office hour suggestions from solutions architects at the AWS loft
in SOHO.

The pipeline takes us from bcl files to fastq files and finally to GEX
UMI counts. If we use cellranger's feature barcoding option, we also get ADT and 
HTO counts.

![A diagram of the cellranger pipeline][cellranger_pipeline_diagram]

## Architecture
For a high-level walkthrough of the components our pipeline uses, visit
[this document](./docs/Architecture.md)

![A diagram of high-level pipeline architecture][architecture_diagram]

*Batch itself doesn't pull the image from ECR. Batch requests an EC2 
instance and that EC2 instance pulls our image from ECR and runs it.

## Running the Pipeline
In order to run the pipeline, the user must do the following:

1. Set up a root directory for the experiment on AWS s3. For our team, that means
creating a subdirectory in the `10x-data-backup` bucket.

Our experiment directories use the following naming convention:
{run id}_{himc pool #}_{sequencing date}

If the experiment has pooled runs, we use the same naming convention, using a `-`
to separate runs. For example:

`run406_himc40_071018-run407_himc40_071118`

2. Create a `raw_data` subfolder in the root experiment directory and add the bcl 
file(s).

3. Create a yaml configuration file for the experiment.

For more information on setting up your configuration file, please visit these
annotated exaple configuration files:
 - [simple example](./docs/example-config-simple.yaml)
 - [feature barcoding & pooled sequencing runs example](./docs/example-config-pooled-feature-barcoding.yaml)

4. From the root of this repository, run the following command, substituting the
path to your yaml configuration file.

`./scripts/submit configs/config.yaml`

## Development

To run the pipeline during development, we recommend using a command like the below, 
substituting your own configuration yaml file. This will ensure that any changes 
are reflected in the Docker images on AWS ECR.

`./make-all-versions.sh push-latest && ./scripts/submit configs/config.yaml`

In development, we' always use the latest version of our images, e.g. `402084680610.dkr.ecr.us-east-1.amazonaws.com/cellranger-3.0.2-bcl2fastq-2.20.0:latest`. This is because the particular image that a job uses is hard-coded in the job definition; if we weren't using `latest`, then, every time we wanted to test a new version of the image, we'd have to 1. push and then 2. update the job definition's image tag to be the git commit tag that we just pushed .

To keep a tight feedback loop, it's best to perform as much development as you
can locally. For example, if you're making changes to the `./bin/run_mkfastq` script, you might be able to validate your changes locally and not waste time waiting for Batch to do its thing; you could use the following workflow:

1. Make the image you need using `make build` (we won't run `make push` now because we don't need to upload our image to ECR yet.)
2. `docker run` the image you just made. The following command is just one way that you might run mkfastq locally. To break it down: `-e DEBUG=true` helps to get debug output from our scripts; the line after that allows us to pass our AWS credentials to the container, so that we can pull raw data from S3; the `--memory` and `--cpus` options help us to ensure that the container doesn't use all of our computer's resources; the very last line, beginning with `run_mkfastq`, shows the script that we want to run and the input JSON that we're passing to it. 
```sh
docker run \
    -e DEBUG=true \
    $(< ~/.aws/credentials tail -2 | tr -d ' ' | sed -r 's/^(.*)=/-e \U\1=\E/' | tr '\n' ' ') \
    --memory 10g \
    --cpus $(( $(nproc) / 2 )) \
    cellranger-2.2.0-bcl2fastq-2.20.0:latest \
    run_mkfastq '{"bcl_file": "cellranger-tiny-bcl-1.2.0.tar.gz", "experiment_name": "runtinybcl_himc0_111618", "run_id": "tinybcl", "samples": [{"name": "test_sample", "index_location": "SI-P03-C9"}]}'
```

By default, cellranger will try to use as much resources as it can; we
use `docker run`'s `--memory` and `--cpus` flag in order to limit the
resources available to the container, and by extension to cellranger,
the process running inside that container.

## Potential Next Steps:
- Automatically migrate fastq files from S3 to Glacier after 1 year
- Automatically migrate bcl file from S3 to Glacier after 1 month
- Account for feature barcoding experiments where the CITE-seq samples may come
from a different combination of bcl files than the GEX samples.
- Use an AWS lambda function to auto-detect raw data and config files on s3 and
initialize the pipeline

[cellranger_pipeline_diagram]: docs/cellranger_pipeline_diagram.png
[architecture_diagram]: docs/cellranger_pipeline_archictecture.png
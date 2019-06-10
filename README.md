# Cellranger AWS Pipeline

We deploy the 10X Genomics [cellranger pipeline](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/what-is-cell-ranger) on AWS. This pipeline builds upon
previous work done by Nick (following the AWS batch genomics [example](https://aws.amazon.com/blogs/compute/building-high-throughput-genomics-batch-workflows-on-aws-introduction-part-1-of-4/) and office
hour suggestions from solutions architects at the AWS loft in SOHO.

## High-Level Architecture

## Building the Pipeline
For a high-level walkthrough of the steps taken to build the pipeline, visit
[this document](./docs/Building_the_Pipeline.md)

## Running the Pipeline
To run the pipeline, we recommend using a command like the below, substituting your
own configuration yaml file. This will ensure that any changes are reflected in 
the Docker images on AWS ECR.

`./make-all-versions.sh push-latest && ./scripts/submit configs/config.yaml`

For more information on setting up your configuration file, please visit [this document](./docs/configuration_files.md)

## Development

To run this stuff locally, you might run a command like this:

```sh
docker run \
    -e DEBUG=true \
    $(< ~/.aws/credentials tail -2 | tr -d ' ' | sed -r 's/^(.*)=/-e \U\1=\E/' | tr '\n' ' ') \
    --memory 10g \
    --cpus $(( $(nproc) / 2 )) \
    cellranger-2.2.0-bcl2fastq-2.20.0:latest \
    mkfastq '{"bcl_file": "cellranger-tiny-bcl-1.2.0.tar.gz", "experiment_name": "runtinybcl_himc0_111618", "run_id": "tinybcl", "samples": [{"name": "test_sample", "index_location": "SI-P03-C9"}]}'
```

By default, cellranger will try to use as much resources as it can; we
use `docker run`'s `--memory` and `--cpus` flag in order to limit the
resources available to the container, and by extension to cellranger,
the process running inside that container.






### Potential Next Steps:
- Automatically migrate fastq files from S3 to Glacier after 1 year
- Automatically migrate bcl file from S3 to Glacier after 1 month
- Account for feature barcoding experiments where the CITE-seq samples may come
from a different combination of bcl files than the GEX samples.
- Reintegrate cloudformation
- Use an AWS lambda function to auto-detect raw data and config files on s3 and
initialize the pipeline

# Architecture

## S3

### `10x-pipeline`

We have an S3 bucket called `10x-pipeline`. At the top-level, there
are three keys: `reference_transcriptome`, `software`, and
`oligo_sequences`.

For example:

```
10x-pipeline/
	oligo_sequences/
		adt_hto_bc_sequences.csv
		citeseq_sample_indices.csv
	reference_transcriptome/
		GRCh38/
			refdata-cellranger-GRCh38-1.2.0.tar.gz
			refdata-cellranger-GRCh38-3.0.0.tar.gz
		hg19/
			refdata-cellranger-hg19-1.2.0.tar.gz
			refdata-cellranger-hg19-3.0.0.tar.gz
		mm10/
			refdata-cellranger-mm10-1.2.0.tar.gz
			refdata-cellranger-mm10-3.0.0.tar.gz
		vdj/
			refdata-cellranger-vdj-2.0.0.tar.gz
	software/
		bcl2fastq/
			bcl2fastq2-v2.20.0-linux-x86-64.zip
		cellranger/
			cellranger-2.2.0.tar.gz
			cellranger-3.0.2.tar.gz
```

#### `oligo_sequences`

This is the source of truth for up-to-date oligo sequences CSVs. New
oligo sequence must be added to these files for use with the
cellranger pipeline. These files include sample index and ADT/HTO
oligo sequences.

#### `reference_transcriptome`

Under `reference_transcriptome`, there are keys are the names of
reference transcriptomes, each of which contain `tar.gz` files for
different versions of the reference transcriptome. The `tar.gz` files
are named consistently so that obtaining different versions of a
reference transcriptome is just a matter of construci

Many of the ref-data files can be downloaded from the 10x genomics
site [here][10x-genomics-downloads]. Ultimately, when decompressed,
you'll be left with a directory including the following top-level
items:

- `fasta/`
- `genes/`
- `pickle/`
- `star/`
- `README.BEFORE.MODIFYING`
- `reference.json`
- `version`

Our executables expect unarchived reference transcriptomes to have
this directory structure.

#### `software`

The software can be downloaded from [10X
Genomics][10x-genomics-downloads] and [Illumina][illumina-downloads],
respectively. We mirror these files in our S3 bucket to provide a
consistent and reliable way of downloading these softwares for use in
our automation.

### `10-data-backup`

We have an s3 bucket called `10-data-backup`. The cellranger pipeline
reads raw data from this bucket, exports processed data and analysis
results to this bucket. The cellranger pipeline consumes raw data on a
per-experiment basis by downloading the files under
`10-data-backup/<experiment_name>/raw_data/`.

We sometimes start with fastqs, instead of bcls, in which case:

- we don't need to run a processing step;
- and the fastq files must be uploaded manually according to our
  naming convention.

#### Naming Conventions

Our experiment directories use the following naming convention: `{run
id}_{himc pool #}_{sequencing date}`

If the experiment has pooled runs, we use the same naming convention,
using a `-` to separate runs. For example:

`run406_himc40_071018-run407_himc40_071118`

If we're starting with fastq files, the fastq files must be stored
under the `experiment_name/sample_id/fastqs/run_id/` folder.

Note that we do not have any naming conventions around bcl archives.

For example:
```
10x-data-backup/
	experiment_name/
		raw_data/
			bcl_filename_run1.tar.gz
			bcl_filename_run2.tar.gz
		sample_id_A/
			fastqs/
				run1/
					...fastq.gz
				run2/
					...fastq.gz
			cellranger_count_output/
				reference_transcriptome/
					outs/
						...
					...
		sample_id_B/
			fastqs/
				run1/
					...fastq.gz
				run2/
					...fastq.gz
			cellranger_count_output/
				reference_transcriptome/
					outs/
						...
					...
		sample_id_A-A/
			fastqs/
				run1/
					...fastq.gz
				run2/
					...fastq.gz
		sample_id_A-H/
			fastqs/
				run1/
					...fastq.gz
				run2/
					...fastq.gz
	fastqs_metadata/
		citeseq/
			run1/
				Stats/
				Reports/
			run2/
				Stats/
				Reports/
		gex/
			run1/
				Stats/
				Reports/
			run2/
				Stats/
				Reports/

```

#### `fastqs_metdata`

The fastqs metadata is stored on a per run basis. It includes
information that may be helpful for troubleshooting.

For example, the `DemuxSummary` files under `Stats` can be used to
troubleshoot the demultiplexing step in the case that we seem to have
provided an inaccurate sample index. The `Most Popular Unknown Index
Sequences` section of the files will contain barcode sequences that
correspond to 10x sample index sequences found
[here][10x-genomics-sample-indices].

## Docker

The pipeline runs by running code in containers on AWS. Our
`cellranger-$CELLRANGER_VERSION-bcl2fastq-$BCL2FASTQ_VERSION` images
contain those softwares (at the versions named) and the executables in
this repo's top-level `bin` directory. These images are run by AWS
Batch.

### `Makefile`

The `Makefile` enables easier docker builds; the `Makefile` commands
are short, easy to remember, and consistent.

In production, we pin the version of the code that is being used;
namely, we enforce that the pipeline runs the code in this repo as of
a particular commit (for example, `abc123`). This is helpful, because
we can tell just by glancing at the AWS Batch console, what code is
running in our production pipeline; if we were always using `latest`,
then it would be more difficult to determine the version of the code
being run. For development, `latest` is useful for making a tighter
feedback loop.

### `Dockerfile`

The `Dockerfile` is parameterized with `CELLRANGER_VERSION` and
`BCL2FASTQ_VERSION`. This makes sense for us, because we need
different images that contain different versions of those softwares,
and also because everything else about the images should be the
same. This is DRYer than having two nearly identical `Dockerfile`s.

## ECR repository

The AWS ECR repository enables us to distribute our images; namely,
when we push our images to ECR, AWS Batch can then pull them and use
them. Images can be pushed to ECR by running `make push` from the root
of this repo.

## AMI

We use an ECS-optimized AMI with 1TB storage at `/docker_scratch`. See
the [AMI readme file](../ami/README.md) for details on how we built
the AMI.

## IAM roles

AWS Batch runs our containers with an IAM role, `cellranger-pipeline`,
that allows the container to interact with S3. That role provides:

- read and write access to `10x-data-backup` S3 bucket (via the
  `s3-10x-data-backup-read-write` IAM policy)
- read access to `10x-pipeline` S3 bucket (via the
  `s3-10x-pipeline-read` IAM policy)

There are also some default IAM roles that we assign to AWS Batch
resources, for example the role that allows AWS Batch to pull our
images from ECR.

## Batch

These jobs run our Docker images with 124GB of memory and 16 CPUs, and
make use of the 1TB of disk provided by the AMI.

### Compute Environment

The compute environment is a resource (CPU, memory) pool. The compute
environment defines the minimum resources available and the maximum
resources available. If we are using all of the compute environment's
resources, then jobs will be queued, having to wait until running jobs
complete until they can be started.

### Job Queue

The job queue associates a job with a compute environment. The job
queue is transparent unless the compute environment is at full
capacity and jobs must wait to be run.

### Job Definition

The job definition is a template that we use when submitting jobs.

## Scripting

Our pipeline relies on various python and bash scripts which can be
found in the top-level, `scripts`, and `bin` directories. These
scripts are responsible for tasks including the following:

- submitting jobs to AWS Batch
- pushing Dockerfile changes to AWS ECR
- validating our yaml config file
- running `mkfastq`, `bcl2fastq`, `count`, and `vdj`

[10x-genomics-downloads]: https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest
[illumina-downloads]: https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software/downloads.html
[10x-genomics-sample-indices]: https://support.10xgenomics.com/single-cell-gene-expression/index/doc/specifications-sample-index-sets-for-single-cell-3

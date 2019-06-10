# Steps Taken to Build Pipeline
This document provides a high-level walkthrough of how the pipeline was built.
Names and organization may be modified at your own discretion.

## S3 infrastructure
1. Establish an S3 bucket `10x-pipeline` with the following structure:
```
10x-pipeline
	reference_transcriptome
		GRCh38
			refdata-cellranger-GRCh38-1.2.0.tar.gz
			refdata-cellranger-GRCh38-3.0.0.tar.gz
		hg19
			refdata-cellranger-hg19-1.2.0.tar.gz
			refdata-cellranger-hg19-3.0.0.tar.gz
		mm10
			refdata-cellranger-mm10-1.2.0.tar.gz
			refdata-cellranger-mm10-3.0.0.tar.gz
		vdj
			refdata-cellranger-vdj-2.0.0.tar.gz
	software
		bcl2fastq
			bcl2fastq2-v2.20.0-linux-x86-64.zip
		cellranger
			cellranger-2.2.0.tar.gz
			cellranger-3.0.2.tar.gz
	oligo_sequences
		adt_hto_bc_sequences.csv
		citeseq_sample_indices.csv
```

Many of the ref-data files can be downloaded from the 10x genomics site [here](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest). Ultimately,
when decompressed, you'll be left with a directory including the following top-level items:
- `fasta/`
- `genes/`
- `pickle/`
- `star/`
- `README.BEFORE.MODIFYING`
- `reference.json`
- `version`

The software can be downloaded from [10X Genomics](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest) and [Illumina](https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software/downloads.html), respectively.

The files under `oligo_sequences` can be found under this repo's own `oligo_sequences` directory. These files include sample index and ADT/HTO oligo
sequences.

2. Establish a `10-data-backup` bucket with the following structure. Of note, our 
pipeline itself will export data in a way that conforms with our desired structure.
We only need to add the bcl fil(s) in the `10-data-backup/raw_data/` directory.
```
10x-data-backup
	experiment_name
		raw_data
			bcl_filename_run1.tar.gz
			bcl_filename_run2.tar.gz
		sample_id_A
			fastqs
				run1
					...fastq.gz
				run2
					...fastq.gz
			cellranger_count_output
				reference_transcriptome
					outs/
						...
					...
		sample_id_B
			fastqs
				run1
					...fastq.gz
				run2
					...fastq.gz
			cellranger_count_output
				reference_transcriptome
					outs/
						...
					...
		sample_id_A-A
			fastqs
				run1
					...fastq.gz
				run2
					...fastq.gz
		sample_id_A-H
			fastqs
				run1
					...fastq.gz
				run2
					...fastq.gz
	fastqs_metadata
		citeseq
			run1
				Stats
				Reports
			run2
				Stats
				Reports
		gex
			run1
				Stats
				Reports
			run2
				Stats
				Reports

```


## Docker
1. Create `Makefile` to enable shorter Docker-related commands in the future.
We anticipate using the git commit sha in order to identify the source of different
versions of our `Dockerfile`.
2. Make Dockerfile with build args
3. Build Docker image via make command
4. Make ECR repo
5. Push image to ECR repo

## AMI and IAM roles
6. Create AMI with 1TB storage
7. Create IAM role `cellranger-pipeline`
	- Attach 2 IAM policies
		- one policy to read and write to 10x-data-backup (s3-10x-data-backup-read-write)
		- one policy to read to 10x-pipeline (s3-10x-pipeline-read)

## Batch
8. Create Batch resource; compute environment
9. Create Batch job definition: cellranger-pipeline-mkfastq


## Scripting
10. Write submit script to invoke lambda function and pass it yaml config contents
11. Create lambda function via AWS GUI
	- Write `lambda_function.py` script to be executed by lambda function
	- Create json schema to validate yaml config file
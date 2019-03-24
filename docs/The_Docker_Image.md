# The cellranger-bcl2fastq Docker image

The Dockerfile at the root of this repo defines an image that contains
cellranger and bcl2fastq. This is the image run by the AWS Batch jobs.

Using build args, we can use one Dockerfile to generate Docker images
for whatever combination of cellranger and bcl2fastq versions we need.

## Working with Docker images

### Building a Docker image

Run `make` at the base of this repo. The `Makefile` designates the
default versions of cellranger and bcl2fastq with the values of the
`CELLRANGER_VERSION` and `BCL2FASTQ_VERSION` variables near the top of
the file.

#### Other versions

If you need to build an image for some other combination of versions,
you can do that. For example, you want to build an image for cellranger
version `3.0.2` and bcl2fastq `2.20.0`, you can run
`CELLRANGER_VERSION=3.0.2 BCL2FASTQ_VERSION=2.20.0 make`.

### Pushing Docker images to ECR

We push our Docker images to our AWS ECR registry. As a one-time step,
you'll need AWS credentials.

1. If you're not authenticated with ECR, run `eval $(aws ecr get-login
   --no-include-email)` at the command line.
2. Run `make push`.

Note that you can use `make push` to push all of the Docker images
that `make` can generate. For example, you want to push an image for
cellranger version `3.0.2` and bcl2fastq `2.20.0`, you can run
`CELLRANGER_VERSION=3.0.2 BCL2FASTQ_VERSION=2.20.0 make push`.

#### Pushing an image for a new version combination

If you're pushing an image for a new version combination, say
cellranger `3.0.2` and bcl2fastq `2.20.0`, for the very first time,
you'' see an error like this in the output from `make push`:

    name unknown: The repository with name 'cellranger-3.0.2-bc2lfastq-2.20.0' does not exist in the registry with id '402084680610'

In that case, you'll need to run this command before pushing:

    aws ecr create-repository --repository-name 'cellranger-3.0.2-bc2lfastq-2.20.0'

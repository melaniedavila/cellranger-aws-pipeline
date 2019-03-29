1. Look into how lambda functions works. Try trivial example.
2. What do the docker images need to have? software, scripts, etc.?
3. Talk to Adeeb re strategy
4. Batch stuff
	a. Define a compute environment
		i. Create an AMI with 1TB of disk
	b. Define a job queue
		i. find out what you need to do this
	c. Define jobs??
5. Fitting these things together
	a. how can we pass args from lambda to batch?
	b. should probably push images to Amazon's container registry. this should be EASY.

# Docker Image

The most basic image needs to have these things:
- cellranger v 3.0.2 + bcl2fastq v 2.20.0
- python3.6
	RUN pip3 install awscli --upgrade
	RUN pip3 install yaml

Test image by invoking python, aws, cellranger, and bcl2fastq

## Second iteration

Parametrize this Dockerfile so that we can use one Dockerfile to build either of these images:
- cellranger v 2.2.0 + bcl2fastq v 2.20.0
- cellranger v 3.0.2 + bcl2fastq v 2.20.0

This can be accomplished easily with "build args". 
See Dockerfile_build_arg_example
Recall the shell commands we ran and their output:

$ docker build -f Dockerfile_build_arg_example ./tmp/ # should error
$ docker build --build-arg base=ubuntu -f Dockerfile_build_arg_example ./tmp/ # should work! we buit an image based on ubuntu
$ docker build --build-arg base=alpine -f Dockerfile_build_arg_example ./tmp/ # should work! we buit an image based on alpine

## Useful things to know for testing

docker build: reads Dockerfile, make images
docker run: takes image and 'runs' a container

you can run containers interactively. test that way.

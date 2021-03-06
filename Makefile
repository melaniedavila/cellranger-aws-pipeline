AWS_PROFILE?=default
REGISTRY=402084680610.dkr.ecr.us-east-1.amazonaws.com
NOCACHE?=false

BCL2FASTQ_VERSION?="2.20.0"
CELLRANGER_VERSION?="2.2.0"
GIT_COMMIT:=$(shell git rev-parse HEAD | cut -c-7)
IMAGE=cellranger-$(CELLRANGER_VERSION)-bcl2fastq-$(BCL2FASTQ_VERSION)

.PHONY: all build push push-latest clean ami

all: build

build:
	@printf '* Building %s\n' "$(IMAGE)"
	@docker build \
		-t $(IMAGE) \
		-t $(REGISTRY)/$(IMAGE) \
		-t $(REGISTRY)/$(IMAGE):$(GIT_COMMIT) \
		--build-arg CELLRANGER_VERSION=$(CELLRANGER_VERSION) \
		--build-arg BCL2FASTQ_VERSION=$(BCL2FASTQ_VERSION) \
		--label commit=$(GIT_COMMIT) \
		--no-cache=$(NOCACHE) .

push: build
	@printf '* Pushing %s\n' "$(REGISTRY)/$(IMAGE):$(GIT_COMMIT)"
	@docker push $(REGISTRY)/$(IMAGE):$(GIT_COMMIT)

push-latest: build
	@printf '* Pushing %s\n' "$(REGISTRY)/$(IMAGE)"
	@docker push $(REGISTRY)/$(IMAGE)

clean:
	@docker rmi -f $(shell docker images -q $(IMAGE) | uniq)

ami:
	@printf '* Building AMI\n'
	@packer build \
		-var git_sha=$(GIT_COMMIT) \
		-var AWS_PROFILE=$(AWS_PROFILE) \
		 ./ami/cellranger-pipeline.json

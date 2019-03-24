REGISTRY?=$(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com
NOCACHE?=false

BCL2FASTQ_VERSION?="2.20.0"
CELLRANGER_VERSION?="2.2.0"
GIT_COMMIT:=$(shell git rev-parse HEAD | cut -c-7)
IMAGE=cellranger-$(CELLRANGER_VERSION)-bc2lfastq-$(BCL2FASTQ_VERSION)

.PHONY: all build push push-latest clean test

all: build

build:
	@printf '* Building %s\n' "$(IMAGE)"
	@docker build \
		-t $(IMAGE) \
		-t $(REGISTRY)/$(IMAGE) \
		-t $(REGISTRY)/$(IMAGE):$(GIT_COMMIT) \
		--label commit=$(GIT_COMMIT) \
		--no-cache=$(NOCACHE) .

push: build test
	@printf '* Pushing %s\n' "$(REGISTRY)/$(IMAGE):$(GIT_COMMIT)"
	@docker push $(REGISTRY)/$(IMAGE):$(GIT_COMMIT)

push-latest: build test
	@printf '* Pushing %s\n' "$(REGISTRY)/$(IMAGE)"
	@docker push $(REGISTRY)/$(IMAGE)

clean:
	@docker rmi -f $(shell docker images -q $(IMAGE) | uniq)
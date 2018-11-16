###############################################
### Dockerfile for 10X Genomics Cell Ranger ###
###############################################

# Based on
FROM python:3.6

# File Author / Maintainer
MAINTAINER Nicolas Fernandez <nickfloresfernandez@gmail.com>

# Install some utilities

# Install bcl2fastq. mkfastq requires it.
# TODO: update to version 2.2.0
RUN apt-get update \
 && apt-get install -y alien unzip wget \
 && wget https://support.illumina.com/content/dam/illumina-support/documents/downloads/software/bcl2fastq/bcl2fastq2-v2-19-1-linux.zip \
 && unzip bcl2fastq2*.zip \
 && alien bcl2fastq2*.rpm \
 && dpkg -i bcl2fastq2*.deb \
 && rm bcl2fastq2*.deb bcl2fastq2*.rpm bcl2fastq2*.zip

# TODO: update to version 2.2.0
COPY software/cellranger-2.1.0.tar.gz /tmp

# Install cellranger
RUN cd /tmp/ && \
	mv cellranger-2.1.0.tar.gz /opt/ && \
	cd /opt/ && \
	tar -xzvf cellranger-2.1.0.tar.gz && \
	rm -f cellranger-2.1.0.tar.gz

# Python requirements
RUN pip3 install boto3 awscli
RUN pip3 install botocore==1.7.13
RUN pip3 install awscli --upgrade
RUN pip3 install pandas

COPY scripts/common_utils /common_utils
COPY scripts/run_cellranger_pipeline.py /

# path
ENV PATH /opt/cellranger-2.1.0:$PATH

# We add an entrypoint in order to avoid entering a python REPL upon running
# the docker image.
ENTRYPOINT ["python", "run_cellranger_pipeline.py"]
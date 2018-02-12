###############################################
### Dockerfile for 10X Genomics Cell Ranger ###
###############################################

# Based on
# FROM centos:7
FROM python:3.5

# File Author / Maintainer
MAINTAINER Nicolas Fernandez <nickfloresfernandez@gmail.com>

# Install some utilities

# Install bcl2fastq. mkfastq requires it.
RUN apt-get update \
 && apt-get install -y alien unzip wget \
 && wget https://support.illumina.com/content/dam/illumina-support/documents/downloads/software/bcl2fastq/bcl2fastq2-v2-19-1-linux.zip \
 && unzip bcl2fastq2*.zip \
 && alien bcl2fastq2*.rpm \
 && dpkg -i bcl2fastq2*.deb \
 && rm bcl2fastq2*.deb bcl2fastq2*.rpm bcl2fastq2*.zip

COPY cellranger-2.1.0.tar.gz /tmp
COPY tiny-bcl /tiny-bcl/
# COPY refdata-cellranger/refdata-cellranger-GRCh38-1.2.0 refdata-cellranger-GRCh38-1.2.0/

# Install cellranger
RUN cd /tmp/ && \
	mv cellranger-2.1.0.tar.gz /opt/ && \
	cd /opt/ && \
	tar -xzvf cellranger-2.1.0.tar.gz && \
	rm -f cellranger-2.1.0.tar.gz

# path
ENV PATH /opt/cellranger-2.1.0:$PATH


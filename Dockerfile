###############################################
### Dockerfile for 10X Genomics Cell Ranger ###
###############################################

# Based on
FROM centos:7

# File Author / Maintainer
MAINTAINER Tiandao Li <litd99@gmail.com>

# Install some utilities
RUN yum install -y \
	file \
	git \
	sssd-client \
	which \
	wget \
	unzip

# Install bcl2fastq
RUN cd /tmp/ && \
	wget https://support.illumina.com/content/dam/illumina-support/documents/downloads/software/bcl2fastq/bcl2fastq2-v2-19-1-linux.zip && \
	unzip bcl2fastq2-v2-19-1-linux.zip && \
	yum -y --nogpgcheck localinstall bcl2fastq2-v2.19.1.403-Linux-x86_64.rpm && \
	rm -rf bcl2fastq2-v2-19-1-linux.zip
 	
# Install cellranger
RUN cd /tmp/ && \
	wget -O cellranger-2.0.1.tar.gz "http://cf.10xgenomics.com/releases/cell-exp/cellranger-2.0.1.tar.gz?Expires=1501815005&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cDovL2NmLjEweGdlbm9taWNzLmNvbS9yZWxlYXNlcy9jZWxsLWV4cC9jZWxscmFuZ2VyLTIuMC4xLnRhci5neiIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTUwMTgxNTAwNX19fV19&Signature=bZBpP5m7Fv6X9LlWzNDCihS2LnoKyY0BFtAWvpPQMYAFJDx6avqOCYI0CvLzUml5JxPv3t4qvqDFSAEHFc59xm13198zQGSM~u1nBo4XIYonfUrzF6mytLxAo4nX8EL7ziBh3TEqSuU1OSdZX1aWWWnce24D851tXGpMIGVE3tgSr2FJZ3kTIRsloMDPY6aof4ROp4R1U0PeS8U0VyU9SxdsNvUi9FlVMgr1FFWD0wn42pdcESwo5B7Yg3M0b89bWOSbbc7vgCzbF~nctYHZ4bFqpLtXbNkmgROYm3Wzrje1n-1QqOydflKAk6DkiAmt3s9nj04V5b8PvUqSYCTu-w__&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA" && \	
	mv cellranger-2.0.1.tar.gz /opt/ && \
	cd /opt/ && \
	tar -xzvf cellranger-2.0.1.tar.gz && \
	rm -f cellranger-2.0.1.tar.gz

# path
ENV PATH /opt/cellranger-2.0.1:$PATH


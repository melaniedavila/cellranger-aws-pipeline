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
	wget -O cellranger-2.0.1.tar.gz "http://cf.10xgenomics.com/releases/cell-exp/cellranger-2.0.1.tar.gz?Expires=1501659669&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cDovL2NmLjEweGdlbm9taWNzLmNvbS9yZWxlYXNlcy9jZWxsLWV4cC9jZWxscmFuZ2VyLTIuMC4xLnRhci5neiIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTUwMTY1OTY2OX19fV19&Signature=Xuz1NFXv~rODK6k1Fh5za8Us0X78kpfrxPNQGpMXPHXxOttx81ilMu18WaEUIknvjGIB6oSCbQOtX7qWgcY18J6nYbd3FFfL8FHuXgg~NwPKdNUatAJEah4GRZmdpcm82SfSOvp241KYMYSZnx-zVeY~Gsyw5r0798O4MLMHSgnYTE22tJjr~AsIene09vDOfkqT1Cx4HRqfi9mFZ4PT3f7dfhCGw5EJtM1-NcLFAfY0CGfreBrDdev903cbGMaJGr-8xaWkuYplxkNh3VcaFpYvV7QnMTUA6qqCObMeZ5P6jzqrTf-QyyX2JgObXDFgYokt5-wwNcghHxjYe9eG2Q__&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA" && \
	mv cellranger-2.0.1.tar.gz /opt/ && \
	cd /opt/ && \
	tar -xzvf cellranger-2.0.1.tar.gz && \
	rm -f cellranger-2.0.1.tar.gz

# path
ENV PATH /opt/cellranger-2.0.1:$PATH

